// ignore_for_file: avoid_print

/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * A simple put request
 */

import 'dart:async';
import 'package:coap/coap.dart';
import 'config/coap_config.dart';

FutureOr<void> main() async {
  final conf = CoapConfig();
  final baseUri = Uri(scheme: 'coap', host: 'coap.me', port: conf.defaultPort);
  final client = CoapClient(baseUri, config: conf);

  final opt = UriQueryOption(
    '${LinkFormatParameter.title.short}=This is an SJH Put request',
  );

  try {
    print('Sending put /create1 to ${baseUri.host}');
    final response = await client.put(
      Uri(path: 'create1'),
      options: [opt],
      payload: 'SJHTestPut',
    );
    print('/create1 response status: ${response.statusCodeString}');
  } on Exception catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
