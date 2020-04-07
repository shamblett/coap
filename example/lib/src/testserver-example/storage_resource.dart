/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * A request for the storage test server resource
 */

import 'dart:async';
import 'dart:io';

import 'package:coap/coap.dart';
import '../../config/coap_config.dart';

// ignore_for_file: omit_local_variable_types
// ignore_for_file: unnecessary_final
// ignore_for_file: cascade_invocations
// ignore_for_file: avoid_print

FutureOr<void> main(List<String> args) async {
  // Create a configuration class. Logging levels can be specified in the
  // configuration file.
  final DefaultCoapConfig conf = CoapConfig();

  // Build the request uri, note that the request paths/query parameters can be changed
  // on the request anytime after this initial setup.
  const String host = 'localhost';

  final Uri uri = Uri(scheme: 'coap', host: host, port: conf.defaultPort);

  // Create the client.
  // The method we are using creates its own request so we do not
  // need to supply one.
  // The current request is always available from the client.
  final CoapClient client = CoapClient(uri, conf);

  // Adjust the response timeout if needed, defaults to 32767 milliseconds
  client.timeout = 10000;

  // Create the request for the get request
  final CoapRequest request = CoapRequest.newGet();
  request.addUriPath('storage');
  client.request = request;

  print('EXAMPLE - Sending get request to $host, waiting for response....');

  final CoapResponse response = await client.get();
  if (response != null) {
    print('EXAMPLE - Response receieved, this is all you get!');
  } else {
    print('EXAMPLE - no response received');
  }

  // Clean up
  client.close();

  exit(0);
}
