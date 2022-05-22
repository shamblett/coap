/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * Deleting a resource
 */

import 'dart:async';
import 'package:coap/coap.dart';
import 'config/coap_config.dart';

FutureOr<void> main(List<String> args) async {
  final conf = CoapConfig();
  final uri = Uri.parse("coap://californium.eclipseprojects.io/test");
  final client = CoapClient(conf);

  try {
    print('Sending delete ${uri.path} to ${uri.host}');
    final response = await client.delete(uri);

    print('/test response status: ${response.statusCodeString}');
  } catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
