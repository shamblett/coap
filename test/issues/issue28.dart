import 'dart:async';
import 'package:coap/coap.dart';
import 'config/coap_config.dart';

FutureOr<void> main() async {
  final conf = CoapConfig();
  final uri = Uri(scheme: 'coap', host: 'coap.me', port: conf.defaultPort);
  final client = CoapClient(uri, conf);

  for (var i = 0; i < 100; i++) {
    final request = CoapRequest.newGet()..addUriPath('large');

    print('EXAMPLE::Request Number >>> $i');
    final stopwatch = Stopwatch()..start();
    await client.send(request);
    print('EXAMPLE::Stopwatch time >>> ${stopwatch.elapsedMilliseconds}');

    await Future<void>.delayed(Duration(seconds: 10));
  }

  client.close();
}
