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
  final uri = Uri(scheme: 'coap', host: 'coap.me', port: conf.defaultPort);
  final client = CoapClient(uri, conf);

  final opt = CoapOption.createUriQuery(
    '${LinkFormatParameter.title.short}=This is an SJH Post request',
  );

  try {
    print('Sending post /large-create to ${uri.host}');
    var response = await client.post(
      'large-create',
      options: [opt],
      payload: 'SJHTestPost',
    );
    print('/large-create response status: ${response.statusCodeString}');

    print('Sending get /large-create to ${uri.host}');
    response = await client.get('large-create');
    print('/large-create response: ${response.payloadString}');
    print('E-Tags : ${response.etags.join(',')}');
  } on Exception catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
