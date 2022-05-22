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

FutureOr main() async {
  final conf = CoapConfig();
  final baseUri = Uri.parse('coap://californium.eclipseprojects.io');
  final client = CoapClient(conf);

  // Create the request for the get request
  final obsUri = baseUri.replace(path: "obs");
  final reqObs = CoapRequest.newGet(obsUri);

  try {
    print('Observing ${obsUri.path} on ${baseUri.host}');
    final obs = await client.observe(reqObs);
    obs.stream.listen((e) {
      print('/obs response: ${e.resp.payloadString}');
    });

    final obsNonUri = baseUri.replace(path: "obs-non");
    final reqObsNon = CoapRequest(obsNonUri, CoapCode.get, confirmable: false);

    print('Observing ${obsNonUri.path} on ${obsNonUri.host}');
    final obsNon = await client.observe(reqObsNon);
    obsNon.stream.listen((e) {
      print('${obsNonUri.path} response: ${e.resp.payloadString}');
    });

    final largeUri = baseUri.replace(path: "large");
    final testUri = baseUri.replace(path: "test");
    final separateUri = baseUri.replace(path: "separate");

    print(largeUri);

    final futures = <Future<void>>[];
    print('Sending get ${largeUri.path} to ${largeUri.host}');
    futures.add(client
        .get(largeUri)
        .then((resp) => print('/large response: ${resp.payloadString}')));

    print('Sending get ${testUri.path} to ${testUri.host}');
    futures.add(client
        .get(testUri)
        .then((resp) => print('/test response: ${resp.payloadString}')));

    print('Sending get ${separateUri.path} to ${separateUri.host}');
    futures.add(client
        .get(separateUri)
        .then((resp) => print('/separate response: ${resp.payloadString}')));

    print('Waiting until get requests are done');
    await Future.wait(futures);

    await client.cancelObserveProactive(obs);

    print('Waiting 20 seconds for /obs-non results');
    await Future.delayed(Duration(seconds: 20));

    await client.cancelObserveProactive(obsNon);
  } catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
