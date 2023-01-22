// ignore_for_file: avoid_print

/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * Multiple clients used in the same application
 */

import 'dart:async';
import 'package:coap/coap.dart';

FutureOr<void> main() async {
  final uri1 = Uri(scheme: 'coap', host: 'coap.me', path: 'hello');
  final client = CoapClient();

  final uri2 = Uri(
    scheme: 'coap',
    host: 'californium.eclipseprojects.io',
    path: 'test',
  );

  try {
    print('Sending get /hello to ${uri1.host}');
    var response = await client.get(uri1);
    print('/hello response: ${response.payloadString}');

    print('Sending get /test to ${uri2.host}');
    response = await client.get(uri2);
    print('/test response: ${response.payloadString}');
  } on Exception catch (e) {
    print('CoAP encountered an exception: $e');
  }

  // Clean up
  await client.close();
}
