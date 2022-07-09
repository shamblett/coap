// ignore_for_file: avoid_print

/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * Multiple asynchronous requests, including observe
 */

import 'dart:async';
import 'package:coap/coap.dart';
import 'config/coap_config.dart';

FutureOr<void> main() async {
  final conf = CoapConfig();
  final uri = Uri(
    scheme: 'coap',
    host: 'californium.eclipseprojects.io',
    port: conf.defaultPort,
  );
  final client = CoapClient(uri, conf);

  // Create the request for the get request
  final reqObs = CoapRequest.newGet()..uriPath = 'obs';

  try {
    print('Observing /obs on ${uri.host}');
    final obs = await client.observe(reqObs);
    obs.stream.listen((final e) {
      print('/obs response: ${e.resp.payloadString}');
    });

    final reqObsNon = CoapRequest(CoapCode.get, confirmable: false)
      ..uriPath = 'obs-non';

    print('Observing /obs-non on ${uri.host}');
    final obsNon = await client.observe(reqObsNon);
    obsNon.stream.listen((final e) {
      print('/obs-non response: ${e.resp.payloadString}');
    });

    final futures = <Future<void>>[];
    print('Sending get /large to ${uri.host}');
    futures.add(
      client.get('large').then(
            (final resp) => print('/large response: ${resp.payloadString}'),
          ),
    );

    print('Sending get /test to ${uri.host}');
    futures.add(
      client
          .get('test')
          .then((final resp) => print('/test response: ${resp.payloadString}')),
    );

    print('Sending get /separate to ${uri.host}');
    futures.add(
      client.get('separate').then(
            (final resp) => print('/separate response: ${resp.payloadString}'),
          ),
    );

    print('Waiting until get requests are done');
    await Future.wait(futures);

    await client.cancelObserveProactive(obs);

    print('Waiting 20 seconds for /obs-non results');
    await Future<void>.delayed(const Duration(seconds: 20));

    await client.cancelObserveProactive(obsNon);
  } on Exception catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
