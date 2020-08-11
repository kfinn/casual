import 'dart:convert';

import 'package:action_cable/action_cable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'env_provider.dart';

final cableProvider = Provider<ActionCable>((ref) {
  final env = DotEnv().env;

  final authCredentials = base64Encode(
    utf8.encode('${env["USERNAME"]}:${env["PASSWORD"]}'),
  );

  return ActionCable.Connect(
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
});
