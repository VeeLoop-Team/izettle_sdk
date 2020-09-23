import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const CHARGE_METHOD = "charge";
const START_METHOD = "start";
const REFUND_METHOD = "refund";

class IzettleSdk {
  static const MethodChannel _channel =
      const MethodChannel('vhelp.co.uk/izettle_sdk');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<dynamic> start(String clientId, String callbackUrl,
      {String reinforcedUserAccount}) {
    if (clientId == null) throw ArgumentError("clientId cannot be null");
    if (callbackUrl == null) throw ArgumentError("callbackUrl cannot be null");

    return _channel.invokeMethod(START_METHOD, {
      'clientID': clientId,
      'callbackURL': callbackUrl,
      'reinforcedUserAccount': reinforcedUserAccount
    });
  }

  Future<dynamic> charge(
    double amount, {
    bool enableTipping = false,
    String reference,
  }) {
    if (amount == null) throw ArgumentError("amount cannot be null");

    return _channel.invokeMethod(CHARGE_METHOD, {
      'amount': amount,
      'enableTipping': enableTipping,
      'reference': reference
    });
  }

  Future<dynamic> refund(
    String paymentReference, {
    num amount,
    String refundReference,
  }) {
    if (paymentReference == null)
      throw ArgumentError("paymentReference cannot be null");

    return _channel.invokeMethod(REFUND_METHOD, {
      'ofPayment': paymentReference,
      'amount': amount,
      'refundReference': refundReference,
    });
  }
}

class SampleWidget extends StatefulWidget {
  final String redirectUrl;
  final String enforcedUserAccount;
  final String clientID;

  const SampleWidget({
    Key key,
    this.redirectUrl,
    this.enforcedUserAccount,
    this.clientID,
  }) : super(key: key);

  @override
  _SampleWidgetState createState() => _SampleWidgetState();
}

class _SampleWidgetState extends State<SampleWidget> {
  final sdk = IzettleSdk();
  String _reference;

  _charge() async {
    try {
      _reference = await sdk.charge(10);

      setState(() {});
      print(_reference);
    } on PlatformException catch (e) {
      print(e);
    }

    if (!mounted) return;
  }

  _refund() async {
    try {
      print(await sdk.refund(_reference));

      setState(() {
        _reference = null;
      });
    } on PlatformException catch (e) {
      print(e);
    }

    if (!mounted) return;
  }

  @override
  void initState() {
    sdk.start(
      widget.clientID,
      widget.redirectUrl,
      reinforcedUserAccount: widget.enforcedUserAccount ?? "",
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("REFERENCE: $_reference"),
        MaterialButton(
          onPressed: _reference != null || true ? _refund : null,
          child: Text('Refund'),
        ),
        MaterialButton(
          onPressed: _reference == null ? _charge : null,
          child: Text('Charge'),
        ),
      ],
    );
  }
}
