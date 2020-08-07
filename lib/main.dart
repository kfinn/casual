import 'dart:convert';

import 'package:action_cable/action_cable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_webrtc/webrtc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DotEnv().load('config/.env.local');
  final env = DotEnv().env;

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

  final peerConfig = {
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
    ]
  };
  final peerConnection = await createPeerConnection(peerConfig, {});
  peerConnection.addStream(localStream);
  peerConnection.onIceCandidate = (_) {};
  peerConnection.onIceConnectionState = (_) {};
  peerConnection.onIceGatheringState = (_) {};

  final offerConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };
  final offer = await peerConnection.createOffer(offerConstraints);

  peerConnection.setLocalDescription(offer);

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

  final roomId = env['ROOM_ID'];
  cable.subscribe(
    'Room',
    channelParams: {'id': roomId},
    onSubscribed: () => print('subscribed to room'),
    onDisconnected: () => print('disconnected from room'),
    onMessage: (message) {
      switch (message['event_type']) {
        case 'membership_created':
          cable.performAction(
            'Room',
            action: 'create_offer',
            channelParams: {'id': roomId},
            actionParams: {
              'to_membership_id': message['payload']['membership_id'],
              'sdp': offer.sdp,
            },
          );
          break;

        case 'membership_destroyed':
          break;

        case 'offer_created':
          break;

        case 'answer_created':
          break;
      }
    },
  );

  // send offer to signaling server...
  // _send('offer', {
  //   'to': id,
  //   'from': _selfId,
  //   'description': {'sdp': s.sdp, 'type': s.type},
  //   'session_id': this._sessionId,
  //   'media': media,
  // });

  final localRenderer = RTCVideoRenderer();
  await localRenderer.initialize();
  localRenderer.srcObject = localStream;

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
      body: RTCVideoView(localRenderer),
    );
  }
}
