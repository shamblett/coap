// ignore_for_file: avoid_print

/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * A simple post request
 */

import 'dart:async';
import 'package:coap/coap.dart';
import 'config/coap_config.dart';

FutureOr<void> main() async {
  final conf = CoapConfig();
  final baseUri = Uri(scheme: 'coap', host: 'coap.me', port: conf.defaultPort);
  final client = CoapClient(baseUri, config: conf);

  final opt = UriQueryOption(
    '${LinkFormatParameter.title.short}=This is an SJH Post request',
  );

  try {
    print('Sending post /large-create to ${baseUri.host}');
    var response = await client.post(
      Uri(path: 'large-create'),
      options: [opt],
      payload: 'SJHTestPost',
    );
    print('/large-create response status: ${response.statusCodeString}');
    final resourceLocationPath = response.location.path;
    print('Resource created under $resourceLocationPath');

    print('Sending get $resourceLocationPath to ${baseUri.host}');
    response = await client.get(Uri(path: resourceLocationPath));
    print('$resourceLocationPath response: ${response.payloadString}');
    print('E-Tags : ${response.etags.join(',')}');
  } on Exception catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
