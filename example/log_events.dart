/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * Using the internal request/response stream (for debugging for example)
 */

import 'dart:async';
import 'package:coap/coap.dart';
import 'config/coap_config.dart';
import 'utils.dart';

FutureOr<void> main(List<String> args) async {
  final conf = CoapConfig();
  final uri = Uri.parse("coap://coap.me/large-create");
  final client = CoapClient(conf);

  final opt = CoapOption.createUriQuery(
      '${CoapLinkFormat.title}=This is an SJH Post request');

  // Random large payload
  final payload = getRandomString(length: 2000);

  try {
    print('Listening to the internal request/response event stream');
    client.events.on().listen(print);

    print('Sending post ${uri.path} to ${uri.host}');
    await client.post(uri, payload: payload, options: [opt]);
  } catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
