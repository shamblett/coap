/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * A simple ping request
 */

import 'dart:async';
import 'package:coap/coap.dart';
import 'config/coap_config.dart';

FutureOr<void> main(List<String> args) async {
  final conf = CoapConfig();
  final uri = Uri(
    scheme: 'coap',
    host: 'californium.eclipseprojects.io',
    port: conf.defaultPort,
  );
  final client = CoapClient(uri, conf);

  try {
    print('Pinging client on ${uri.host}');
    final ok = await client.ping();
    if (ok) {
      print('Ping successful');
    } else {
      print('Ping failed');
    }
  } catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
