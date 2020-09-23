import 'package:flutter_dotenv/flutter_dotenv.dart';

String env(String key, [String defaultValue = '']) {
  final value = String.fromEnvironment(key, defaultValue: null) ??
      DotEnv().env[key] ??
      defaultValue;

  return value;
}
