import 'dart:convert';

import 'package:action_cable/action_cable.dart';
import 'package:casual/room_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'local_stream_provider.dart';

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

  runApp(
    ProviderScope(
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: RoomScreen(id: env['ROOM_ID']),
      ),
    ),
  );
}
