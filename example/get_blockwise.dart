/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * A request demonstrating a blockwise (block2) get
 */

import 'dart:async';
import 'package:coap/coap.dart';
import 'config/coap_config.dart';

FutureOr<void> main(List<String> args) async {
  final conf = CoapConfig();
  final uri = Uri(scheme: 'coap', host: 'coap.me', port: conf.defaultPort);
  final client = CoapClient(uri, conf);

  try {
    print('Sending get /large to ${uri.host}');
    final response = await client.get('large');

    print('/large response: ${response.payloadString}');
  } catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
