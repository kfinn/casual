import 'dart:convert';

import 'package:action_cable/action_cable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_webrtc/webrtc.dart';

class Room {
  final ActionCable cable;
  final String roomId;
  final Map<String, RTCPeerConnection> connections = {};
  final Map<String, List<RTCIceCandidate>> bufferedCandidatesByMemberId = {};

  final peerConfig = {
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
    ]
  };
  final sessionContraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  Room({@required this.cable, @required this.roomId}) {
    _setupChannel();
  }

  Future<void> membershipCreated(Map<String, dynamic> payload) async {
    final membershipId = payload['membership_id'];
    final peerConnection = await _findOrCreatePeerConnection(membershipId);

    // final offer = await peerConnection.createOffer(sessionContraints);
    // await peerConnection.setLocalDescription(offer);

    // cable.performAction(
    //   'Room',
    //   action: 'create_offer',
    //   channelParams: {'id': roomId},
    //   actionParams: {
    //     'to_membership_id': payload['membership_id'],
    //     'offer': {
    //       'sdp': offer.sdp,
    //       'type': offer.type,
    //     },
    //   },
    // );
  }

  Future<void> membershipDestroyed(Map<String, dynamic> payload) async {
    final membershipId = payload['membership_id'];
    final peerConnection = _findPeerConnection(membershipId);
    if (peerConnection != null) {
      await peerConnection.close();
      _removePeerConnection(membershipId);
    }
  }

  Future<void> offerCreated(Map<String, dynamic> payload) async {
    final membershipId = payload['from_membership_id'];
    final peerConnection = await _findOrCreatePeerConnection(membershipId);

    final offer = RTCSessionDescription(
      payload['offer']['sdp'],
      payload['offer']['type'],
    );
    await peerConnection.setRemoteDescription(offer);

    final answer = await peerConnection.createAnswer(sessionContraints);
    await peerConnection.setLocalDescription(answer);
    await _applyBufferedCandidates(membershipId);

    cable.performAction(
      'Room',
      action: 'create_answer',
      channelParams: {'id': roomId},
      actionParams: {
        'to_membership_id': payload['from_membership_id'],
        'answer': {
          'sdp': answer.sdp,
          'type': answer.type,
        },
      },
    );
  }

  Future<void> answerCreated(Map<String, dynamic> payload) async {
    final membershipId = payload['from_membership_id'];
    final peerConnection = await _findOrCreatePeerConnection(membershipId);

    final answer = RTCSessionDescription(
      payload['answer']['sdp'],
      payload['answer']['type'],
    );
    await peerConnection.setRemoteDescription(answer);
    await _applyBufferedCandidates(membershipId);
  }

  Future<void> iceCandidateCreated(Map<String, dynamic> payload) async {
    final membershipId = payload['from_membership_id'];
    final peerConnection = await _findOrCreatePeerConnection(membershipId);

    final candidate = RTCIceCandidate(
      payload['candidate']['sdp'],
      payload['candidate']['sdp_mid'],
      payload['candidate']['sdp_mline_index'],
    );
    final hasRemoteDescription = [
      RTCSignalingState.RTCSignalingStateHaveLocalPrAnswer,
      RTCSignalingState.RTCSignalingStateHaveRemotePrAnswer
    ].contains(peerConnection.signalingState);
    if (hasRemoteDescription) {
      await peerConnection.addCandidate(candidate);
    } else {
      final bufferedCandidates = _findOrCreateBufferedCandidates(membershipId);
      bufferedCandidates.add(candidate);
    }
  }

  void _setupChannel() {
    cable.subscribe(
      'Room',
      channelParams: {'id': roomId},
      onSubscribed: () => print('subscribed to room'),
      onDisconnected: () => print('disconnected from room'),
      onMessage: (message) async {
        print(message.toString());

        switch (message['event']) {
          case 'membership_created':
            membershipCreated(message['payload']);
            break;

          case 'membership_destroyed':
            membershipDestroyed(message['payload']);
            break;

          case 'offer_created':
            offerCreated(message['payload']);
            break;

          case 'answer_created':
            answerCreated(message['payload']);
            break;

          case 'ice_candidate_created':
            iceCandidateCreated(message['payload']);
            break;
        }
      },
    );
  }

  RTCPeerConnection _removePeerConnection(String membershipId) {
    return connections.remove(membershipId);
  }

  RTCPeerConnection _findPeerConnection(String membershipId) {
    return connections[membershipId];
  }

  Future<RTCPeerConnection> _findOrCreatePeerConnection(
    String membershipId,
  ) async {
    RTCPeerConnection peerConnection = _findPeerConnection(membershipId);

    if (peerConnection != null) {
      return peerConnection;
    }

    peerConnection = await createPeerConnection(peerConfig, {});

    // peerConnection.addStream(localStream);
    peerConnection.onIceCandidate = (candidate) {
      // print(candidate.toMap());
      cable.performAction(
        'Room',
        action: 'create_ice_candidate',
        channelParams: {'id': roomId},
        actionParams: {
          'to_membership_id': membershipId,
          'candidate': {
            'sdp': candidate.candidate,
            'sdp_mid': candidate.sdpMid,
            'sdp_mline_index': candidate.sdpMlineIndex,
          },
        },
      );
    };
    peerConnection.onRenegotiationNeeded = () async {
      final offer = await peerConnection.createOffer(sessionContraints);

      if (peerConnection.signalingState !=
          RTCSignalingState.RTCSignalingStateStable) {
        print("The connection isn't stable yet; postponing...");
        return;
      }

      await peerConnection.setLocalDescription(offer);

      cable.performAction(
        'Room',
        action: 'create_offer',
        channelParams: {'id': roomId},
        actionParams: {
          'to_membership_id': membershipId,
          'offer': {
            'sdp': offer.sdp,
            'type': offer.type,
          },
        },
      );
    };
    peerConnection.onSignalingState = print;
    peerConnection.onIceConnectionState = print;
    peerConnection.onIceGatheringState = print;
    peerConnection.onAddStream =
        (stream) => print('onAddStream: streamId:${stream.id}');
    peerConnection.onRemoveStream =
        (stream) => print('onRemoveStream: streamId:${stream.id}');
    peerConnection.onAddTrack = (stream, track) => print(
          'onAddTrack: streamId:${stream.id}' +
              ',trackId:${track.id}' +
              ',trackEnabled:${track.enabled}' +
              ',trackKind:${track.kind}' +
              ',trackLabel:${track.label}',
        );
    peerConnection.onRemoveTrack = (stream, track) => print(
          'onRemoveTrack: streamId:${stream.id}' +
              ',trackId:${track.id}' +
              ',trackEnabled:${track.enabled}' +
              ',trackKind:${track.kind}' +
              ',trackLabel:${track.label}',
        );

    return peerConnection;
  }

  List<RTCIceCandidate> _findOrCreateBufferedCandidates(String membershipId) {
    if (!bufferedCandidatesByMemberId.containsKey(membershipId)) {
      bufferedCandidatesByMemberId[membershipId] = [];
    }
    return bufferedCandidatesByMemberId[membershipId];
  }

  Future<void> _applyBufferedCandidates(String membershipId) async {
    final peerConnection = await _findOrCreatePeerConnection(membershipId);
    final bufferedCandidates = _findOrCreateBufferedCandidates(membershipId);
    bufferedCandidates.forEach((candidate) async {
      await peerConnection.addCandidate(candidate);
    });
    bufferedCandidates.clear();
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DotEnv().load('config/.env.local');
  final env = DotEnv().env;

  final authCredentials = base64Encode(
    utf8.encode('${env["USERNAME"]}:${env["PASSWORD"]}'),
  );

  final cable = ActionCable.Connect(
    'wss://cajzh.herokuapp.com/cable',
    headers: {
      'Authorization': 'Basic $authCredentials',
      'Origin': 'https://cajzh.herokuapp.com',
    },
    onConnected: () {
      print('connected');
    },
    onConnectionLost: () {
      print('connection lost');
    },
    onCannotConnect: () {
      print('cannot connect');
    },
  );

  final room = Room(cable: cable, roomId: env['ROOM_ID']);

  final mediaConstraints = {
    'audio': true,
    'video': {
      'mandatory': {
        'minWidth': '640', // Provide your own width, height and frame rate here
        'minHeight': '480',
        'minFrameRate': '30',
      },
      'facingMode': 'user',
      'optional': [],
    }
  };
  final localStream = await navigator.getUserMedia(mediaConstraints);
  final localRenderer = RTCVideoRenderer();
  await localRenderer.initialize();
  localRenderer.srcObject = localStream;
  room.connections.values.forEach((c) {
    c.addStream(localStream);
  });

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: HomeScreen(localRenderer: localRenderer),
    ),
  );
}

class HomeScreen extends HookWidget {
  final RTCVideoRenderer localRenderer;

  const HomeScreen({Key key, @required this.localRenderer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('casual')),
      // body: RTCVideoView(localRenderer),
      body: Text('something'),
    );
  }
}
