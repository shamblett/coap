/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * Cancelling retries of an ongoing request
 */

import 'dart:async';
import 'package:coap/coap.dart';
import 'config/coap_config.dart';

FutureOr<void> main(List<String> args) async {
  final conf = CoapConfig();
  final client = CoapClient(conf);

  final cancelUri = Uri.parse("coap://coap.me/doesNotExist");
  final helloUri = Uri.parse("coap://coap.me/hello");

  final cancelThisReq = CoapRequest.newGet(cancelUri);

  try {
    // Ensure this request is not also cancelled
    print('Sending async get ${helloUri.path} to ${helloUri.host}');
    final helloRespFuture = client.get(helloUri);

    print('Sending async get ${cancelUri.path} to ${cancelUri.host}');
    final ignoreThisFuture = client.send(cancelThisReq);

    print('Cancelling get ${cancelUri.path} retries');
    client.cancel(cancelThisReq);

    print('Ignoring ${cancelUri.path} response future');
    ignoreThisFuture.ignore();

    final resp = await helloRespFuture;
    print('${helloUri.path} response: ${resp.payloadString}');

    if (cancelThisReq.retransmits > 0) {
      print('Expected 0 retransmits!');
    }
  } catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
