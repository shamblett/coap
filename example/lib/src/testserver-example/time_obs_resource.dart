/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * A request for the time test server resource, this time with observation
 */

import 'dart:async';

import 'package:coap/coap.dart';
import '../../config/coap_config.dart';

FutureOr<void> main(List<String> args) async {
  // Create a configuration class. Logging levels can be specified in the
  // configuration file.
  final conf = CoapConfig();

  // Build the request uri, note that the request paths/query parameters can be changed
  // on the request anytime after this initial setup.
  const host = 'localhost';

  final uri = Uri(scheme: 'coap', host: host, port: conf.defaultPort);

  // Create the client.
  // The method we are using creates its own request so we do not
  // need to supply one.
  // The current request is always available from the client.
  final client = CoapClient(uri, conf);

  // Adjust the response timeout if needed, defaults to 32767 milliseconds
  //client.timeout = 10000;

  // Create the request for the get request
  final request = CoapRequest.newGet();
  request.addUriPath('time');
  // Mark the request as observable
  request.markObserve();

  client.request = request;

  print('EXAMPLE - Sending get observable request to '
      '$host, waiting for responses ....');
  await client.get();

  // Getting responses form the observable resource
  request.responses.listen((CoapResponse response) {
    print('EXAMPLE - payload: ${response.payloadString}');
  });
}
