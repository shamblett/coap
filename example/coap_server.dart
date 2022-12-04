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
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:coap/coap.dart';

FutureOr<void> main() async {
  final server = await CoapServer.bind(
    InternetAddress.anyIPv4,
    CoapUriScheme.coap,
  );
  server.listen(
    (final request) async {
      print('Received the following request: $request\n');
      print('Sending response...\n');
      server
        ..respond(
          request,
          payload: Uint8List.fromList(utf8.encode('Hello World')),
          responseCode: ResponseCode.content,
          contentFormat: CoapMediaType.applicationTdJson,
        )
        ..close();
    },
    onDone: () => print('Done!'),
  );
}
