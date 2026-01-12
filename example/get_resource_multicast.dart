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
import 'dart:io';
import 'package:coap/coap.dart';

FutureOr<void> main() async {
  final iface = Platform.environment['COAP_IFACE'];
  final uri =
      iface == null
          ? Uri.parse('coap://${MulticastAddress.allCOAPNodesLinkLocalIPV6}')
          : Uri.parse(
            'coap://[${MulticastAddress.allCOAPNodesLinkLocalIPV6.address}%$iface]',
          );
  final client = CoapClient(uri);

  try {
    final request = CoapRequest.get(Uri(path: '/.well-known/core'));
    request.token = CoapConstants.emptyToken;

    await for (final response in client.sendMulticast(request)) {
      print(response.payloadString);
      break;
    }
  } on Exception catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
