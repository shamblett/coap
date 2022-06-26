// ignore_for_file: avoid_print

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

FutureOr<void> main(final List<String> args) async {
  final conf = CoapConfig();
  final uri = Uri(scheme: 'coap', host: 'coap.me', port: conf.defaultPort);
  final client = CoapClient(uri, conf);

  final cancelThisReq = CoapRequest.newGet()..uriPath = 'doesNotExist';

  try {
    // Ensure this request is not also cancelled
    print('Sending async get /hello to ${uri.host}');
    final helloRespFuture = client.get('hello');

    print('Sending async get /doesNotExist to ${uri.host}');
    final ignoreThisFuture = client.send(cancelThisReq);

    print('Cancelling get /doesNotExist retries');
    client.cancel(cancelThisReq);

    print('Ignoring /doesNotExist response future');
    ignoreThisFuture.ignore();

    final resp = await helloRespFuture;
    print('/hello response: ${resp.payloadString}');

    if (cancelThisReq.retransmits > 0) {
      print('Expected 0 retransmits!');
    }
  } on Exception catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
