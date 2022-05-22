/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * One client making a request to two endpoints
 */

import 'dart:async';
import 'package:coap/coap.dart';
import 'config/coap_config.dart';

FutureOr<void> main(List<String> args) async {
  final conf = CoapConfig();
  final client = CoapClient(conf);

  final uri1 = Uri.parse("coap://coap.me/hello");
  final uri2 = Uri.parse("coap://californium.eclipseprojects.io/test");

  try {
    print('Sending get ${uri1.path} to ${uri1.host}');
    var response = await client.get(uri1);
    print('${uri1.path} response: ${response.payloadString}');

    print('Sending get ${uri2.path} to ${uri2.host}');
    response = await client.get(uri2);
    print('${uri2.path} response: ${response.payloadString}');
  } catch (e) {
    print('CoAP encountered an exception: $e');
  }

  // Clean up
  client.close();
}
