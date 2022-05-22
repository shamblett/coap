/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * A request demonstrating a blockwise (block1) post
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
    print('Sending post ${uri.path} to ${uri.host}');
    var response = await client.post(uri, payload: payload, options: [opt]);
    print('${uri.path} response status: ${response.statusCodeString}');

    print('Sending get ${uri.path} to ${uri.host}');
    response = await client.get(uri);
    print('${uri.path} response:\n${response.payloadString}');
    print('E-Tags : ${response.etags.join(',')}');
  } catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
