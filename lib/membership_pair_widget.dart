import 'package:casual/cable_provider.dart';
import 'package:casual/membership_pair_channel.dart';
import 'package:casual/renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'local_stream_provider.dart';
import 'membership_pair.dart';
import 'membership_pair_entry.dart';
import 'web_rtc_answer.dart';
import 'web_rtc_ice_candidate.dart';
import 'web_rtc_offer.dart';

const PEER_CONFIG = {
  'iceServers': [
    {'url': 'stun:stun.l.google.com:19302'},
  ]
};

const SESSION_CONSTRAINTS = {
  'mandatory': {
    'OfferToReceiveAudio': true,
    'OfferToReceiveVideo': true,
  },
  'optional': [],
};

class MembershipPairWidget extends HookWidget {
  final MembershipPairEntry membershipPairEntry;

  const MembershipPairWidget({Key key, @required this.membershipPairEntry})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cable = useProvider(cableProvider);

    final remoteWebRtcOfferState = useState<WebRtcOffer>(null);
    final remoteWebRtcAnswerState = useState<WebRtcAnswer>(null);
    final hasRemoteDescriptionState = useState(false);
    final remoteWebRtcIceCandidatesState = useState(Set<WebRtcIceCandidate>());
    final addedRemoteWebRtcIceCandidatesState =
        useState(Set<WebRtcIceCandidate>());

    final onWebRtcOfferCreated = (WebRtcOffer webRtcOffer) {
      if (remoteWebRtcOfferState.value != null &&
          remoteWebRtcOfferState.value != webRtcOffer) {
        print("ERROR: received a second distinct remote offer");
        return;
      }
      remoteWebRtcOfferState.value = webRtcOffer;
    };
    final onWebRtcAnswerCreated = (WebRtcAnswer webRtcAnswer) {
      if (remoteWebRtcAnswerState.value != null &&
          remoteWebRtcAnswerState.value != webRtcAnswer) {
        print("ERROR: received a second distinct remote answer");
        return;
      }
      remoteWebRtcAnswerState.value = webRtcAnswer;
    };
    final onWebRtcIceCandidateCreated =
        (WebRtcIceCandidate webRtcIceCandidate) {
      remoteWebRtcIceCandidatesState.value = remoteWebRtcIceCandidatesState
          .value
          .union(Set.from([webRtcIceCandidate]));
    };
    final updateMembershipPair = (MembershipPair membershipPair) {
      if (membershipPair.webRtcOffer != null) {
        onWebRtcOfferCreated(membershipPair.webRtcOffer);
      }
      if (membershipPair.webRtcAnswer != null) {
        onWebRtcAnswerCreated(membershipPair.webRtcAnswer);
      }
      membershipPair.webRtcIceCandidates.forEach((webRtcIceCandidate) {
        onWebRtcIceCandidateCreated(webRtcIceCandidate);
      });
    };

    final membershipPairChannelState = useState(
      MembershipPairChannel(
        cable: cable,
        id: membershipPairEntry.membershipPairId,
        onConnected: updateMembershipPair,
        onWebRtcOfferCreated: onWebRtcOfferCreated,
        onWebRtcAnswerCreated: onWebRtcAnswerCreated,
        onWebRtcIceCandidateCreated: onWebRtcIceCandidateCreated,
      ),
    );
    useEffect(() {
      membershipPairChannelState.value.subscribe();
      return () => membershipPairChannelState.value.unsubscribe();
    }, [membershipPairChannelState.value]);

    final localStreamFuture = useProvider(localStreamProvider.future);
    final peerConnectionState = useState<RTCPeerConnection>(null);
    final remoteStreamState = useState<MediaStream>(null);

    final onIceCandidate = (RTCIceCandidate iceCandidate) {
      print('onIceCandidate: ${iceCandidate.candidate}');
      membershipPairChannelState.value.createWebRtcIceCandidate(
          sdp: iceCandidate.candidate,
          sdpMid: iceCandidate.sdpMid,
          sdpMlineIndex: iceCandidate.sdpMlineIndex);
    };
    final onAddStream = (MediaStream stream) {
      print('onAddStream: ${stream.id}');
      remoteStreamState.value = stream;
    };

    useEffect(() {
      Future.wait([localStreamFuture, createPeerConnection(PEER_CONFIG, {})])
          .then((resolvedFutures) {
        final MediaStream localStream = resolvedFutures[0];
        final RTCPeerConnection peerConnection = resolvedFutures[1];

        peerConnection.addStream(localStream);
        peerConnection.onIceCandidate = onIceCandidate;
        peerConnection.onAddStream = onAddStream;

        peerConnectionState.value = peerConnection;
      });

      return () => peerConnectionState.value?.dispose();
    }, []);

    useEffect(() {
      final peerConnection = peerConnectionState.value;
      if (peerConnection == null || !membershipPairEntry.older) {
        return;
      }

      () async {
        print('createOffer');
        final offer = await peerConnection.createOffer(SESSION_CONSTRAINTS);
        await peerConnection.setLocalDescription(
          RTCSessionDescription(offer.sdp, offer.type),
        );
        membershipPairChannelState.value.createWebRtcOffer(sdp: offer.sdp);
      }();

      return null;
    }, [peerConnectionState.value]);

    useEffect(() {
      final peerConnection = peerConnectionState.value;
      final remoteWebRtcOffer = remoteWebRtcOfferState.value;
      if (peerConnection == null || remoteWebRtcOffer == null) {
        return;
      }

      () async {
        print('createAnswer');
        await peerConnection.setRemoteDescription(
          RTCSessionDescription(remoteWebRtcOffer.sdp, 'offer'),
        );
        hasRemoteDescriptionState.value = true;

        final answer = await peerConnection.createAnswer(SESSION_CONSTRAINTS);
        await peerConnection.setLocalDescription(
          RTCSessionDescription(answer.sdp, answer.type),
        );
        membershipPairChannelState.value.createWebRtcAnswer(sdp: answer.sdp);
      }();

      return null;
    }, [peerConnectionState.value, remoteWebRtcOfferState.value]);

    useEffect(() {
      final peerConnection = peerConnectionState.value;
      final remoteWebRtcAnswer = remoteWebRtcAnswerState.value;
      if (peerConnection == null || remoteWebRtcAnswer == null) {
        return;
      }

      () async {
        print('receivedAnswer');
        await peerConnection.setRemoteDescription(
          RTCSessionDescription(remoteWebRtcAnswer.sdp, 'answer'),
        );
        hasRemoteDescriptionState.value = true;
      }();

      return null;
    }, [peerConnectionState.value, remoteWebRtcAnswerState.value]);

    useEffect(() {
      final peerConnection = peerConnectionState.value;
      if (peerConnection == null) {
        return;
      }

      if (!hasRemoteDescriptionState.value) {
        print("received ice candiates before a remote description");
        return;
      }

      () async {
        final webRtcIceCandidatesToAdd = remoteWebRtcIceCandidatesState.value
            .difference(addedRemoteWebRtcIceCandidatesState.value);
        addedRemoteWebRtcIceCandidatesState.value =
            addedRemoteWebRtcIceCandidatesState.value
                .union(remoteWebRtcIceCandidatesState.value);
        await Future.wait(webRtcIceCandidatesToAdd.map((webRtcIceCandidate) {
          print("addCandidate $webRtcIceCandidate");
          return peerConnection.addCandidate(RTCIceCandidate(
              webRtcIceCandidate.sdp,
              webRtcIceCandidate.sdpMid,
              webRtcIceCandidate.sdpMlineIndex));
        }));
      }();

      return null;
    }, [
      peerConnectionState.value,
      hasRemoteDescriptionState.value,
      remoteWebRtcIceCandidatesState.value
    ]);

    return Renderer(mediaStream: remoteStreamState.value);
  }
}
