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
import 'config/coap_config.dart';

FutureOr<void> main(final List<String> args) async {
  final conf1 = CoapConfig();
  final uri1 = Uri(scheme: 'coap', host: 'coap.me', port: conf1.defaultPort);
  final client1 = CoapClient(uri1, conf1);

  final conf2 = CoapConfig();
  final uri2 = Uri(
    scheme: 'coap',
    host: 'californium.eclipseprojects.io',
    port: conf2.defaultPort,
  );
  final client2 = CoapClient(uri2, conf2);

  try {
    print('Sending get /hello to ${uri1.host}');
    var response = await client1.get('hello');
    print('/hello response: ${response.payloadString}');

    print('Sending get /test to ${uri2.host}');
    response = await client2.get('test');
    print('/test response: ${response.payloadString}');
  } on Exception catch (e) {
    print('CoAP encountered an exception: $e');
  }

  // Clean up
  client1.close();
  client2.close();
}
