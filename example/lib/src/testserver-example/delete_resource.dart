/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * A delete request is used to delete data on the storage
 * testserver resource. Note please run the put_create_resource example first.
 */

import 'dart:async';
import 'dart:io';
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

  // Create the request for the delete request
  final request = CoapRequest.newDelete();
  request.addUriPath('storage');
  client.request = request;

  print('EXAMPLE - Sending delete request to $host, waiting for response....');

  final response = await client.delete();
  if (response != null) {
    print('EXAMPLE - delete response received, sending get');
    print('EXAMPLE - Payload: ${response.payloadString}');
    print('EXAMPLE - response code is ${response.codeString}');
  } else {
    print('EXAMPLE - no delete response received');
  }

  // Clean up
  client.close();

  exit(0);
}
