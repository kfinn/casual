import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final envProvider = FutureProvider<Map<String, String>>((ref) async {
  await DotEnv().load('config/.env.local');
  return DotEnv().env;
});
