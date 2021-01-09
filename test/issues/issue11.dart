import 'dart:async';
import 'package:coap/coap.dart';
import 'config/coap_config.dart';

FutureOr main() async {
  const host = 'coap.me';
  final conf = CoapConfig();

  final uri =
      Uri(scheme: CoapConstants.uriScheme, host: host, port: conf.defaultPort);

  final client = CoapClient(uri, conf);

  final path = 'inline';
  final query = 'status/2/2/1';
  final pathPut = 'inline';
  final queryPut = 'lamp';
  var count = 1;

  // Adjust the response timeout if needed, defaults to 32767 milliseconds
  client.timeout = 10000;

  void getPut(int count) async {
    // Create the request for the get request
    final request = CoapRequest.newGet();

    request.addUriPath(path);
    request.addUriQuery(query);

    client.request = request;

    print('ISSUE: Sending GET request  - $count...');
    final response = await client.get();
    if (response != null) {
      print('ISSUE: - GET response received  - $count');
      print(response.payloadString);
    } else {
      print('ISSUE: - no response received  - $count');
      client.cancelRequest();
      client.close();
      return;
    }

    // Create the request for the Put request
    final requestPut = CoapRequest.newPut();

    requestPut.addUriPath(pathPut);
    requestPut.addUriQuery(queryPut);

    client.request = requestPut;

    print('ISSUE: Sending PUT request  - $count...');
    final responsePut = await client.put('The PUT payload');

    if (responsePut != null) {
      print('ISSUE: - PUT response received  - $count');
      print(responsePut.payloadString);
      client.cancelRequest();
    } else {
      print('ISSUE: - no response received  - $count');
      client.cancelRequest();
      client.close();
      return;
    }
  }

  print('ISSUE: First getPut');
  await getPut(count);
  print('ISSUE: Second getPut');
  await getPut(++count);

  print('ISSUE: closing client');
  client.close();
  print('ISSUE: exiting test....');
}
