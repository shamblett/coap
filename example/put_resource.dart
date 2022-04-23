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

FutureOr<void> main(List<String> args) async {
  final conf = CoapConfig();
  final uri = Uri(scheme: 'coap', host: 'coap.me', port: conf.defaultPort);
  final client = CoapClient(uri, conf);

  final opt = CoapOption.createUriQuery(
      '${CoapLinkFormat.title}=This is an SJH Put request');

  try {
    print('Sending put /create1 to ${uri.host}');
    var response =
        await client.put('create1', options: [opt], payload: 'SJHTestPut');
    print('/create1 response status: ${response.statusCodeString}');

    client.close();
  } catch (e) {
    print('CoAP encountered an exception: $e');
  }
}
