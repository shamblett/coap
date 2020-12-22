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

// Send get request
  print('ISSUE: Sending GET request...');
  final response = await client.get();
  if (response != null) {
    print('ISSUE: - response received');
    print(response.payloadString);
    client.cancelRequest();
  } else {
    print('ISSUE: - no response received');
    client.cancelRequest();
  }

  print('ISSUE: closing client and exiting....');
  client.close();

  return 0;
}
