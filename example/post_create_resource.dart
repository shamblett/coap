/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * A post request is used to create data on the storage testserver resource
 */

import 'dart:async';
import 'package:coap/coap.dart';
import 'config/coap_config.dart';

FutureOr<void> main(List<String> args) async {
  // Create a configuration class. Logging levels can be specified
  // in the configuration file.
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

  // Create the request for the post request
  final request = CoapRequest.newPost();
  request.addUriPath('large-create');
  // Add a title
  request.addUriQuery('${CoapLinkFormat.title}=This is an SJH Post request');
  client.request = request;

  print('EXAMPLE - Sending post request to $host, waiting for response....');

  var response = await client.post('''
     0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |Ver| T |  TKL  |      Code     |          Message ID           |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |   Token (if any, TKL bytes) ...
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |   Options (if any) ...
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |1 1 1 1 1 1 1 1|    Payload (if any) ...
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

[...]

   Token Length (TKL):  4-bit unsigned integer.  Indicates the length of
      the variable-length Token field (0-8 bytes).  Lengths 9-15 are
      reserved, MUST NOT be sent, and MUST be processed as a message
      format error.

   Code:  8-bit unsigned integer, split into a 3-bit class (most
      significant bits) and a 5-bit detail (least significant bits),
      documented as c.dd where c is a digit from 0 to 7 for the 3-bit
      subfield and dd are two digits from 00 to 31 for the 5-bit
      subfield.  The class can indicate a request (0), a success
      response (2), a client error response (4), or a server error
      response (5).  (All other class values are reserved.)  As a
      special case, Code 0.00 indicates an Empty message.  In case of a
      request, the Code field indicates the Request Method; in case of a
      response a Response Code.  Possible values are maintained in the
      CoAP Code Registries (Section 12.1).  The semantics of requests
      and responses are defined in Section 5.''');
  print('EXAMPLE - post response received, sending get');
  print('EXAMPLE -  Payload: ${response.payloadString}');
  // Now get and check the payload
  final getRequest = CoapRequest.newGet();
  getRequest.addUriPath('large-create');
  client.request = getRequest;
  response = await client.get();
  print('EXAMPLE - get response received');
  print('EXAMPLE - Payload: ${response.payloadString}');
  print('EXAMPLE - E-Tags : ${CoapUtil.iterableToString(response.etags)}');

  // Clean up
  client.close();
}
