/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * Asynchronous vs synchronous benchmark
 */

import 'dart:async';
import 'package:coap/coap.dart';
import 'config/coap_config.dart';

FutureOr main() async {
  final conf = CoapConfig();
  final uri = Uri.parse("coap://coap.me/test");
  final client = CoapClient(conf);

  try {
    // Warm up (create socket etc.)
    await client.get(uri);

    Stopwatch stopwatch = Stopwatch()..start();

    print('Sending 10 async requests...');
    final futures = <Future<void>>[];
    for (var i = 0; i < 10; i++) {
      futures.add(client.get(uri).then((resp) {
        if (resp.code != CoapCode.content) {
          print('Request failed!');
        }
      }));
    }

    // Wait until all requests are done
    await Future.wait(futures);

    print('10 async requests took ${stopwatch.elapsedMilliseconds} ms');

    stopwatch.reset();

    print('Sending 10 sync requests...');
    for (var i = 0; i < 10; i++) {
      final resp = await client.get(uri);
      if (resp.code != CoapCode.content) {
        print('Request failed!');
      }
    }

    print('10 sync requests took ${stopwatch.elapsedMilliseconds} ms');
  } catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
