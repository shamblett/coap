import 'dart:async';
import 'package:coap/coap.dart';
import 'config/coap_config.dart';

FutureOr main() async {
  // Create a configuration class. Logging levels can be specified in the
  // configuration file.
  final conf1 = CoapConfig();
  final conf2 = CoapConfig();

  final uri1 = Uri(
    scheme: 'coap',
    host: 'coap.me',
    port: conf1.defaultPort,
  );

  print('ISSUE - Ping Client1');
  final client1 = CoapClient(uri1, conf1);
  final firstPingResponse = await client1.ping(10000);
  if (firstPingResponse) {
    print('ISSUE - Client1 Ping response OK ');
  } else {
    print('ISSUE  - Client1 Ping failed');
  }
  client1.close();

  final uri2 = Uri(
    scheme: 'coap',
    host: 'coap.me',
    port: conf2.defaultPort,
  );

  print('ISSUE - Ping Client2');
  final client2 = CoapClient(uri2, conf2);
  final secondPingResponse = await client2.ping(20000);
  if (secondPingResponse) {
    print('ISSUE - Client2 Ping response OK ');
  } else {
    print('ISSUE  - Client2 Ping failed');
  }
  client2.close();
}
