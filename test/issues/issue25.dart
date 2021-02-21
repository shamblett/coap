import 'dart:async';
import 'package:coap/coap.dart';
import 'config/coap_config.dart';

FutureOr main() async {
  // Create a configuration class. Logging levels can be specified in the
  // configuration file.
  final conf = CoapConfig();

  // Build the request uri, note that the request paths/query parameters can be changed
  // on the request anytime after this initial setup.
  const host = 'coap.me';

  final uri = Uri(scheme: 'coap', host: host, port: conf.defaultPort);

  // Create the client.
  // The method we are using creates its own request so we do not
  // need to supply one.
  // The current request is always available from the client.
  var client = CoapClient(uri, conf);

  // Create the request for the get request
  final request = CoapRequest.withType(CoapCode.methodGET);
  request.addUriPath('obs');
  print('ISSUE: max retransmit from request is ${request.maxRetransmit}');

  // You can override the configured maxretransmit setting on a request by request basis
  request.maxRetransmit = 2;
  print('ISSUE: max retransmit from request is now ${request.maxRetransmit}');
  // Getting responses from the observable resource
  request.responses.listen((CoapResponse response) {
    print('ISSUE: - payload: ${response.payloadString}');
  });

  client.request = request;

  print('ISSUE: - Sending get request to '
      '$host, waiting for responses ....');
  await client.get();

  print('ISSUE: closing the client and re allocating it and the request');
  client.close();
  client = null;
  client = CoapClient(uri, conf);
  final request2 = CoapRequest.withType(CoapCode.methodGET);
  request2.addUriPath('obs');
  request2.maxRetransmit = 2;
  client.request = request2;

  print('ISSUE: resending');
  await client.get();

}
