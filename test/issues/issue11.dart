import 'package:coap/coap.dart';
import 'config/coap_config.dart';

Future<int> main() async {
  const host = 'coap.me';
  final conf = CoapConfig();

  final uri =
      Uri(scheme: CoapConstants.uriScheme, host: host, port: conf.defaultPort);

  final client = CoapClient(uri, conf);

  final path = 'inline';
  final query = 'status/2/2/1';

// Adjust the response timeout if needed, defaults to 32767 milliseconds
  client.timeout = 10000;

// Create the request for the get request
  final request = CoapRequest.newGet();
// request =
//     CoapRequest.isConfirmable(CoapCode.methodGET, confirmable: false);

  request.addUriPath(path);
  request.addUriQuery(query);

  client.request = request;

  print('ISSUE: Sending GET request...');
  final response = await client.get();
  if (response != null) {
    print('ISSUE: - GET response received');
    print(response.payloadString);
  } else {
    print('ISSUE: - no response received');
    client.cancelRequest();
    client.close();
    return 0;
  }

  final pathPut = 'inline';
  final queryPut = 'lamp';

  // Create the request for the Put request
  final requestPut = CoapRequest.newPut();

  requestPut.addUriPath(pathPut);
  requestPut.addUriQuery(queryPut);

  client.request = requestPut;

  print('ISSUE: Sending PUT request...');
  final responsePut = await client.put('The PUT payload');

  if (responsePut != null) {
    print('ISSUE: - PUT response received');
    print(responsePut.payloadString);
    client.cancelRequest();
  } else {
    print('ISSUE: - no response received');
    client.cancelRequest();
    client.close();
    return 0;
  }

  print('ISSUE: closing client and exiting....');
  client.close();

  return 0;
}
