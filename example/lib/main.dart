import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:izettle_sdk/izettle_sdk.dart';
import 'package:izettle_sdk_example/env.dart';

void main() async {
  await DotEnv().load("./assets/.env");
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SampleWidget(
            redirectUrl: env("IZETTLE_REDIRECT_URL"),
            clientID: env("IZETTLE_CLIENT_ID")),
      ),
    );
  }
}
