// ignore_for_file: avoid_print

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

FutureOr<void> main() async {
  final conf = CoapConfig();
  final baseUri = Uri(
    scheme: 'coap',
    host: 'californium.eclipseprojects.io',
    port: conf.defaultPort,
  );
  final client = CoapClient(baseUri, config: conf);

  try {
    // Warm up (create socket etc.)
    await client.get(Uri(path: 'test'));

    final stopwatch = Stopwatch()..start();

    print('Sending 10 async requests...');
    final futures = <Future<void>>[];
    for (var i = 0; i < 10; i++) {
      futures.add(
        client.get(Uri(path: 'test')).then((final resp) {
          if (resp.responseCode != ResponseCode.content) {
            print('Request failed!');
          }
        }),
      );
    }

    // Wait until all requests are done
    await Future.wait(futures);

    print('10 async requests took ${stopwatch.elapsedMilliseconds} ms');

    stopwatch.reset();

    print('Sending 10 sync requests...');
    for (var i = 0; i < 10; i++) {
      final resp = await client.get(Uri(path: 'test'));
      if (resp.responseCode != ResponseCode.content) {
        print('Request failed!');
      }
    }

    print('10 sync requests took ${stopwatch.elapsedMilliseconds} ms');
  } on Exception catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
