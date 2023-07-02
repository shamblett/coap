// ignore_for_file: avoid_print

import 'dart:core';

import 'package:coap/coap.dart';

/// Tests the basic functionality of the TCP network.
/// Will be replaced with a "real" example later.
Future<void> main() async {
  await connect();
}

Future<void> connect() async {
  final coapClient =
      CoapClient(Uri.parse('coap+tcp://californium.eclipseprojects.io'));

  final response = await coapClient.post(
    Uri(path: 'test'),
    format: CoapMediaType.applicationJson,
    accept: CoapMediaType.applicationCbor,
    payload: 'Hello?',
  );
  print(response);

  coapClient.close();
}
