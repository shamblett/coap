// ignore_for_file: avoid_print

import 'dart:core';
import 'dart:io';

import 'package:coap/coap.dart';

Future<void> startServer() async {
  final server = await ServerSocket.bind(InternetAddress.anyIPv4, 5683);
  server.listen((final connection) async {
    await connection.forEach((final frame) {
      print(frame);

      const responseCode = (2 << 5) + 5;

      const tokenLength = 8;
      const tokenOffset = 2;
      final token = frame.sublist(tokenOffset, tokenOffset + tokenLength);

      final response = [tokenLength, responseCode, ...token];

      connection.add(response);
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
  final coapClient = CoapClient(Uri.parse('coap+tcp://127.0.0.1'));

  final response = await coapClient.get(
    'test',
    options: [ContentFormatOption(40)],
  );
  // TODO(JKRhb): Responses can't be matched at the moment, as the current
  //              implementation requires a message ID which is not defined in
  //              CoAP over TCP.
  print(response);

  coapClient.close();
}
