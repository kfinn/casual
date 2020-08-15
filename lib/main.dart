import 'package:casual/screens/splash_screen.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EquatableConfig.stringify = true;
  await DotEnv().load('config/.env.local');

  runApp(
    ProviderScope(
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: SplashScreen(),
      ),
    ),
  );
}
