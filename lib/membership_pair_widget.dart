import 'package:casual/cable_provider.dart';
import 'package:casual/membership_pair_channel.dart';
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

  const MembershipPairWidget({ Key key, @required this.membershipPairEntry }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cable = useProvider(cableProvider);

    final membershipPairState = useState(MembershipPair.empty());
    final addedWebRtcOffer = useState<WebRtcOffer>(null);
    final addedWebRtcAnswer = useState<WebRtcAnswer>(null);
    final addedWebRtcIceCandidatesState = useState(Set<WebRtcIceCandidate>());

    final updateMembershipPair = (MembershipPair membershipPair) => membershipPairState.value = membershipPair;
    final onWebRtcOfferCreated = (WebRtcOffer webRtcOffer) {
      membershipPairState.value = membershipPairState.value.copyWith(webRtcOffer: webRtcOffer);
    };
    final onWebRtcAnswerCreated = (WebRtcAnswer webRtcAnswer) {
      membershipPairState.value = membershipPairState.value.copyWith(webRtcAnswer: webRtcAnswer);
    };
    final onWebRtcIceCandidateCreated = (WebRtcIceCandidate webRtcIceCandidate) {
      final webRtcIceCandidates = [...membershipPairState.value.webRtcIceCandidates, webRtcIceCandidate];
      membershipPairState.value = membershipPairState.value.copyWith(webRtcIceCandidates: webRtcIceCandidates);
    };

    final membershipPairChannelState = useState(
      MembershipPairChannel(
        cable: cable,
        id: membershipPairEntry.membershipPairId,
        onConnected: updateMembershipPair,
        onWebRtcOfferCreated: onWebRtcOfferCreated,
        onWebRtcAnswerCreated: onWebRtcAnswerCreated,
        onWebRtcIceCandidateCreated: onWebRtcIceCandidateCreated
      )
    );

    useEffect(() {
      membershipPairChannelState.value.subscribe();
      return () => membershipPairChannelState.value.unsubscribe();
    });

    final localStreamFuture = useProvider(localStreamProvider.future);
    final peerConnectionState = useState<RTCPeerConnection>(null);
    final peerConnectionSignalingStateState = useState<RTCSignalingState>(null);
    final remoteStreamState = useState<MediaStream>(null);

    final onSignalingState = (RTCSignalingState signalingState) => peerConnectionSignalingStateState.value = signalingState;
    final onIceCandidate = (RTCIceCandidate iceCandidate) {
      membershipPairChannelState.value.createWebRtcIceCandidate(
        sdp: iceCandidate.candidate,
        sdpMid: iceCandidate.sdpMid,
        sdpMlineIndex: iceCandidate.sdpMlineIndex
      );
    };
    final onAddStream = (MediaStream stream) => remoteStreamState.value = stream;

    useEffect(() {
        Future.wait([
          localStreamFuture,
          createPeerConnection(PEER_CONFIG, {})
        ]).then((resolvedFutures) {
          final MediaStream localStream = resolvedFutures[0];
          final RTCPeerConnection peerConnection = resolvedFutures[1];

          peerConnection.addStream(localStream);
          peerConnection.onSignalingState = onSignalingState;
          peerConnection.onIceCandidate = onIceCandidate;
          peerConnection.onAddStream = onAddStream;

          peerConnectionState.value = peerConnection;
        });

        return () => peerConnectionState.value?.dispose();
    }, []);

    useEffect(() {
      if (peerConnectionState.value == null) {
        return;
      }

      () async {
        final peerConnection = peerConnectionState.value;
        if (membershipPairEntry.older && peerConnectionSignalingStateState.value == RTCSignalingState.RTCSignalingStateStable) {
          final offer = await peerConnection.createOffer(SESSION_CONSTRAINTS);
          await peerConnection.setLocalDescription(RTCSessionDescription(offer.sdp, offer.type));
          membershipPairChannelState.value.createWebRtcOffer(sdp: offer.sdp);
        } else if (membershipPairState.value.webRtcOffer != null && addedWebRtcOffer == null) {
          final webRtcOffer = membershipPairState.value.webRtcOffer;
          await peerConnection.setRemoteDescription(RTCSessionDescription(webRtcOffer.sdp, 'offer'));
          addedWebRtcOffer.value = webRtcOffer;

          final answer = await peerConnection.createAnswer(SESSION_CONSTRAINTS);
          await peerConnection.setLocalDescription(RTCSessionDescription(answer.sdp, answer.type));
          membershipPairChannelState.value.createWebRtcAnswer(sdp: answer.sdp);
        } else if (membershipPairState.value.webRtcAnswer != null && addedWebRtcAnswer == null) {
          final webRtcAnswer = membershipPairState.value.webRtcAnswer;
          await peerConnection.setRemoteDescription(RTCSessionDescription(webRtcAnswer.sdp, 'answer'));
        }

        final canAddIceCandidates = [
          RTCSignalingState.RTCSignalingStateHaveLocalPrAnswer,
          RTCSignalingState.RTCSignalingStateHaveRemotePrAnswer
        ].contains(peerConnectionSignalingStateState.value);
        if (!canAddIceCandidates) {
          return;
        }

        final webRtcIceCandidatesToAdd = Set.from(membershipPairState.value.webRtcIceCandidates).difference(addedWebRtcIceCandidatesState.value);
        await Future.wait(webRtcIceCandidatesToAdd.map((webRtcIceCandidate) async {
          return peerConnection.addCandidate(
            RTCIceCandidate(
              webRtcIceCandidate.sdp,
              webRtcIceCandidate.sdpMid,
              webRtcIceCandidate.sdpMlineIndex
            )
          );
        }));
        addedWebRtcIceCandidatesState.value = addedWebRtcIceCandidatesState.value.union(webRtcIceCandidatesToAdd);
      }();
    }, [
      peerConnectionState.value,
      peerConnectionSignalingStateState.value,
      membershipPairState.value
    ]);

    final rendererState = useState(RTCVideoRenderer());
    final rendererDidInitializeState = useState(false);

    useEffect(() {
      () async {
        await rendererState.value.initialize();
        rendererDidInitializeState.value = true;
      }();
    }, []);

    useEffect(() {
      if (!rendererDidInitializeState.value) {
        return;
      }

      rendererState.value.srcObject = remoteStreamState.value;
    }, [rendererDidInitializeState.value, remoteStreamState.value]);

    return RTCVideoView(rendererState.value);
  }
}
