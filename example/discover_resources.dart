// ignore_for_file: avoid_print

/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * A simple discover request using .well-known/core to discover a servers resource list
 */

import 'dart:async';
import 'package:coap/coap.dart';
import 'config/coap_config.dart';

FutureOr<void> main() async {
  final conf = CoapConfig();
  final baseUri = Uri(scheme: 'coap', host: 'coap.me', port: conf.defaultPort);
  final client = CoapClient(baseUri, config: conf);

  try {
    print('Sending get /discover/.well-known/core to ${baseUri.host}');
    final links = await client.discover();

    print('Discovered resources:');
    links?.forEach(print);
  } on Exception catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
