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
  final uri = Uri.parse("coap://coap.me/create1");
  final client = CoapClient(conf);

  final opt = CoapOption.createUriQuery(
      '${CoapLinkFormat.title}=This is an SJH Put request');

  try {
    print('Sending put ${uri.path} to ${uri.host}');
    var response = await client.put(uri, options: [opt], payload: 'SJHTestPut');
    print('${uri.path} response status: ${response.statusCodeString}');
  } catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
