// ignore_for_file: avoid_print

/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * Example for iterating over responses using sendMulticast().
 *
 * For this to work, you need at least one CoAP node reachable under the
 * link-local IPv6 "All Nodes" multicast address (ff02::1), exposing its
 * resources using `/.well-known/core`.
 */

import 'dart:async';
import 'package:coap/coap.dart';

FutureOr<void> main() async {
  final uri = Uri.parse('coap://${MulticastAddress.allNodesLinkLocalIPV6}');
  final client = CoapClient(uri);

  try {
    final request = CoapRequest.newGet(uri.replace(path: '/.well-known/core'));

    await for (final response in client.sendMulticast(request)) {
      print(response.payloadString);
      break;
    }
  } on Exception catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
