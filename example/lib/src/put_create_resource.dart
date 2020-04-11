/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * A put request is used to create data on the clear1 coap.me resource
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
  // The method we are using creates its own request so we do not
  // need to supply one.
  // The current request is always available from the client.
  final client = CoapClient(uri, conf);

  // Adjust the response timeout if needed, defaults to 32767 milliseconds
  //client.timeout = 10000;

  // Create the request for the put request
  final request = CoapRequest.newPost();
  request.addUriPath('create1');
  // Add a title
  request.addUriQuery('${CoapLinkFormat.title}=This is an SJH post request');
  client.request = request;

  print('EXAMPLE - Sending post request to $host, waiting for response....');

  var response = await client.put('SJHTestPut');
  if (response != null) {
    print('EXAMPLE - post response received, sending get');
    print('EXAMPLE -  Payload: ${response.payloadString}');
    // Now get and check the payload
    final getRequest = CoapRequest.newGet();
    getRequest.addUriPath('create1');
    client.request = getRequest;
    response = await client.get();
    if (response != null) {
      print('EXAMPLE - get response received');
      print('EXAMPLE - Payload: ${response.payloadString}');
      print('EXAMPLE - E-Tags : ${CoapUtil.iterableToString(response.etags)}');
    } else {
      print('EXAMPLE - no get response received');
    }
  } else {
    print('EXAMPLE - no post response received');
  }

  // Clean up
  client.close();

  exit(0);
}
