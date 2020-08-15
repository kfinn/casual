import 'dart:convert';

import 'package:casual/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class LoginScreen extends HookWidget {
  const LoginScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final env = DotEnv().env;
    final emailController = useTextEditingController(text: env['USERNAME']);
    final passwordController = useTextEditingController(text: env['PASSWORD']);

    return Scaffold(
      body: ListView(
        children: [
          Text('Log-in'),
          TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Email',
            ),
            autofillHints: [AutofillHints.username, AutofillHints.email],
          ),
          TextField(
            controller: passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
            ),
            obscureText: true,
            autofillHints: [AutofillHints.password],
          ),
          OutlineButton(
            child: Text('log in'),
            onPressed: () {
              context.read(authProvider).storeToken(
                    _buildDummyToken(
                      emailController.text,
                      passwordController.text,
                    ),
                  );
            },
          ),
        ],
      ),
    );
  }
}

String _buildDummyToken(String email, String password) {
  final value = base64Encode(utf8.encode('$email:$password'));

  return 'Basic $value';
}
