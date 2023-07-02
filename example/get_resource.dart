// ignore_for_file: avoid_print

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

FutureOr<void> main() async {
  final conf = CoapConfig();
  final client = CoapClient(config: conf);

  try {
    // print('Sending get /test to ${uri.host}');
    var response = await client.get(Uri.parse('coap://coap.me/test'));
    print('/test response: ${response.payloadString}');

    // print('Sending get /multi-format (text) to ${uri.host}');
    response = await client.get(Uri.parse('coap://coap.me/multi-format'));
    print('/multi-format (text) response: ${response.payloadString}');

    // print('Sending get /multi-format (xml) to ${uri.host}');
    response = await client.get(
      Uri.parse('coap://coap.me/multi-format'),
      accept: CoapMediaType.applicationXml,
    );
    print('/multi-format (xml) response: ${response.payloadString}');
  } on Exception catch (e) {
    print('CoAP encountered an exception: $e');
  }

  await client.close();
}
