// ignore_for_file: avoid_print

/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * Using the internal request/response stream (for debugging for example)
 */

import 'dart:async';
import 'package:coap/coap.dart';
import 'config/coap_config.dart';
import 'utils.dart';

FutureOr<void> main() async {
  final conf = CoapConfig();
  final baseUri = Uri(scheme: 'coap', host: 'coap.me', port: conf.defaultPort);
  final client = CoapClient(baseUri, config: conf);

  final opt = UriQueryOption(
    '${LinkFormatParameter.title.short}=This is an SJH Post request',
  );

  // Random large payload
  final payload = getRandomString(length: 2000);

  try {
    print('Listening to the internal request/response event stream');
    client.events.on<Object>().listen(print);

    print('Sending post /large-create to ${baseUri.host}');
    await client
        .post(Uri(path: 'large-create'), payload: payload, options: [opt]);
  } on Exception catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
