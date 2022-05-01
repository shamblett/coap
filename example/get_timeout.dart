/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * Demonstrates adjustments to the timeout
 */

import 'dart:async';
import 'package:coap/coap.dart';
import './config/coap_config.dart';

FutureOr main() async {
  final conf = CoapConfig();
  final uri = Uri(scheme: 'coap', host: 'google.com', port: conf.defaultPort);
  final client = CoapClient(uri, conf);

  final request = CoapRequest.newGet();
  request.addUriPath('doesNotExist');

  try {
    final timeout = Duration(milliseconds: 100);
    final stopwatch = Stopwatch()..start();

    print('Sending get /doesNotExist to ${uri.host}');
    print('Timeout set to $timeout');
    await client.send(request, timeout: timeout);
    if (request.isTimedOut) {
      print('Request timed out in ${stopwatch.elapsedMilliseconds} ms');
    }

    client.close();
  } catch (e) {
    print('CoAP encountered an exception: $e');
  }
}
