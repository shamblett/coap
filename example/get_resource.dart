/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * Get requests with different accepted media types
 */

import 'dart:async';
import 'package:coap/coap.dart';
import 'config/coap_config.dart';

FutureOr<void> main(List<String> args) async {
  final conf = CoapConfig();
  final uri = Uri(scheme: 'coap', host: 'coap.me', port: conf.defaultPort);
  final client = CoapClient(uri, conf);

  try {
    print('Sending get /test to ${uri.host}');
    var response = await client.get('test');
    print('/test response: ${response.payloadString}');

    print('Sending get /multi-format (text) to ${uri.host}');
    response = await client.get('multi-format');
    print('/multi-format (text) response: ${response.payloadString}');

    print('Sending get /multi-format (xml) to ${uri.host}');
    response =
        await client.get('multi-format', accept: CoapMediaType.applicationXml);
    print('/multi-format (xml) response: ${response.payloadString}');

    client.close();
  } catch (e) {
    print('CoAP encountered an exception: $e');
  }
}
