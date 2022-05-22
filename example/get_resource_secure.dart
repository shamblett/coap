/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>,
 *          J. Romann <jan.romann@uni-bremen.de
 * Date   : 05/02/2022
 * Copyright :  S.Hamblett
 *
 * Get requests with different accepted media types using CoAPS and a Pre-Shared
 * Key.
 *
 * You need to have a compiled tinyDTLS version available in order to be able
 * to use this example.
 */

import 'dart:async';
import 'package:coap/coap.dart';

final pskCredentials =
    PskCredentials(identity: 'Client_identity', preSharedKey: 'secretPSK');

PskCredentials pskCredentialsCallback(String indentity) {
  return pskCredentials;
}

class DtlsConfig extends DefaultCoapConfig {
  @override
  final dtlsBackend = DtlsBackend.TinyDtls;
}

FutureOr<void> main(List<String> args) async {
  final conf = DtlsConfig();
  final uri = Uri.parse("coaps://californium.eclipseprojects.io/test");
  final client = CoapClient(conf);

  try {
    print('Sending get /test to ${uri.host}');
    var response =
        await client.get(uri, pskCredentialsCallback: pskCredentialsCallback);
    print('/test response: ${response.payloadString}');

    final secondUri = uri.replace(path: 'multi-format');

    print('Sending get ${secondUri.path} (text) to ${secondUri.host}');
    response = await client.get(secondUri);
    print('${secondUri.path} (text) response: ${response.payloadString}');

    print('Sending get ${secondUri.path} (xml) to ${secondUri.host}');
    response =
        await client.get(secondUri, accept: CoapMediaType.applicationXml);
    print('${secondUri.path} (xml) response: ${response.payloadString}');
  } catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
