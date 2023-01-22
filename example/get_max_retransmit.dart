// ignore_for_file: avoid_print

/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * Demonstrates adjustments to the retransmission configuration
 */

import 'dart:async';
import 'package:coap/coap.dart';
import './config/coap_config.dart';

FutureOr<void> main() async {
  final conf = CoapConfig();
  final uri = Uri(
    scheme: 'coap',
    host: 'google.com',
    port: conf.defaultPort,
    path: 'doesNotExist',
  );
  final client = CoapClient(config: conf);

  print('maxRetransmit config: ${conf.maxRetransmit}');

  final request = CoapRequest.newGet(uri);
  print('maxRetransmit request: ${request.maxRetransmit} (0=config default)');

  try {
    // Override maxRetransmit for this request
    request.maxRetransmit = 2;
    print('maxRetransmit altered request: ${request.maxRetransmit}');

    print('Sending get /doesNotExist to ${uri.host}');
    print('Waiting for timeout, this might take a while...');
    final resp = await client.send(request);

    if (request.isTimedOut) {
      print('Timeout! Client retransmitted ${request.retransmits} times');
    } else {
      print('Expected timeout did not happen, something could be wrong');
    }

    print('Response: $resp');
  } on Exception catch (e) {
    print('CoAP encountered an exception: $e');
  }

  await client.close();
}
