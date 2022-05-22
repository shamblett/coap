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

FutureOr<void> main(List<String> args) async {
  final conf1 = CoapConfig();
  final uri1 = Uri.parse("coap://coap.me/hello");
  final client1 = CoapClient(conf1);

  final conf2 = CoapConfig();
  final uri2 = Uri.parse("coap://californium.eclipseprojects.io/test");
  final client2 = CoapClient(conf2);

  try {
    print('Sending get ${uri1.path} to ${uri1.host}');
    var response = await client1.get(uri1);
    print('${uri1.path} response: ${response.payloadString}');

    print('Sending get ${uri2.path} to ${uri2.host}');
    response = await client2.get(uri2);
    print('${uri2.path} response: ${response.payloadString}');
  } catch (e) {
    print('CoAP encountered an exception: $e');
  }

  // Clean up
  client1.close();
  client2.close();
}
