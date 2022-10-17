// ignore_for_file: avoid_print

/*
 * Package : Coap
 * Author : J. Romann <jan.romann@uni-bremen.de>
 * Date   : 10/15/2022
 * Copyright :  J. Romann
 *
 * CoAP Server example
 */

import 'dart:async';
import 'dart:io';
import 'package:coap/coap.dart';

FutureOr<void> main() async {
  final server = await CoapServer.bind(
    InternetAddress.anyIPv4,
    CoapUriScheme.coap,
  );
  server.listen(
    (final request) async {
      print('Received the following request: $request\n');
      final response = CoapResponse.createResponse(
        request,
        CoapCode.content,
        CoapMessageType.ack,
      )
        ..id = request.id
        ..payloadString = 'Hello World!';
      print('Sending response: $response\n');
      server
        ..sendResponse(response, request.source!, request.uriPort)
        ..close();
    },
    onDone: () => print('Done!'),
  );
}
