import 'package:action_cable/action_cable.dart';
import 'package:casual/auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final cableProvider = Provider<ActionCable>((ref) {
  final auth = ref.watch(authProvider.state);
  final token =
      auth.maybeWhen(authenticated: (token) => token, orElse: () => null);

  final cable = ActionCable.Connect(
    'wss://cajzh.herokuapp.com/cable',
    headers: {
      'Authorization': token,
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

  ref.onDispose(() => cable.disconnect());

  return cable;
});
