// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:coap/coap.dart';

Future<void> startServer() async {
  final server = await ServerSocket.bind(InternetAddress.anyIPv4, 5683);
  server.listen((final connection) async {
    await connection.forEach((final frame) async {
      print(frame);

      const responseCode = (2 << 5) + 5;

      const tokenLength = 8;
      const tokenOffset = 3;
      final token = frame.sublist(tokenOffset, tokenOffset + tokenLength);
      final payload = utf8.encode('Hello');

      final response = [
        ((payload.length + 1) << 4) | tokenLength,
        responseCode,
        ...token,
        255,
        ...payload,
      ];

      connection.add(response);
      await connection.close();
      await server.close();
    });
  });
}

/// Tests the basic functionality of the TCP network.
/// Will be replaced with a "real" example later.
Future<void> main() async {
  await startServer();
  await connect();
}

Future<void> connect() async {
  final coapClient =
      CoapClient(Uri.parse('coap+tcp://californium.eclipseprojects.io:5683'));

  final response = await coapClient.get(
    Uri(path: 'test'),
    // format: CoapMediaType.applicationJson,
    accept: CoapMediaType.applicationCbor,
    // payload: 'Hello?',
  );
  print(response);

  coapClient.close();
}
