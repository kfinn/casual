import 'package:casual/models/auth.dart';
import 'package:casual/screens/login_screen.dart';
import 'package:casual/screens/room_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SplashScreen extends HookWidget {
  const SplashScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = useProvider(authProvider.state);

    return auth.when(
      authenticated: (_) => RoomScreen(id: DotEnv().env['ROOM_ID']),
      unauthenticated: () => LoginScreen(),
      loading: () => Center(child: CircularProgressIndicator()),
    );
  }
}
