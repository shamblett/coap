/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * A simple ping request
 */

import 'dart:async';
import 'dart:io';
import 'package:coap/coap.dart';
import '../config/coap_config.dart';

FutureOr<void> main(List<String> args) async {
  // Create a configuration class. Logging levels can be specified in
  // the configuration file.
  final conf = CoapConfig();

  // Build the request uri, note that the request paths/query parameters can be changed
  // on the request anytime after this initial setup.
  const host = 'coap.me';

  final uri = Uri(scheme: 'coap', host: host, port: conf.defaultPort);

  // Create the client.
  // The method we are using creates its own request so we do
  // not need to supply one.
  // The current request is always available from the client.
  final client = CoapClient(uri, conf);

  print('EXAMPLE - Ping client, sending ping request to '
      '$host, waiting for response....');

  // Perform the ping
  final pingOk = await client.ping(10000);

  if (pingOk) {
    print('EXAMPLE - Ping response OK ');
  } else {
    print('EXAMPLE  - Ping failed');
  }

  // Cancel the current request
  print('EXAMPLE  - Cleaning up');
  client.close();

  exit(0);
}
