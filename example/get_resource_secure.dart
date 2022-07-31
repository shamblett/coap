// ignore_for_file: avoid_print

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
import 'dart:convert';
import 'dart:typed_data';
import 'package:coap/coap.dart';

final identity = Uint8List.fromList(utf8.encode('Client_identity'));
final preSharedKey = Uint8List.fromList(utf8.encode('secretPSK'));

final pskCredentials =
    PskCredentials(identity: identity, preSharedKey: preSharedKey);

PskCredentials pskCredentialsCallback(final Uint8List indentity) =>
    pskCredentials;

class DtlsConfig extends DefaultCoapConfig {
  @override
  final dtlsBackend = DtlsBackend.TinyDtls;
}

FutureOr<void> main(final List<String> args) async {
  final conf = DtlsConfig();
  final uri = Uri(
    scheme: 'coaps',
    host: 'californium.eclipseprojects.io',
    port: conf.defaultSecurePort,
  );
  final client =
      CoapClient(uri, conf, pskCredentialsCallback: pskCredentialsCallback);

  try {
    print('Sending get /test to ${uri.host}');
    var response = await client.get('test');
    print('/test response: ${response.payloadString}');

    print('Sending get /multi-format (text) to ${uri.host}');
    response = await client.get('multi-format');
    print('/multi-format (text) response: ${response.payloadString}');

    print('Sending get /multi-format (xml) to ${uri.host}');
    response =
        await client.get('multi-format', accept: CoapMediaType.applicationXml);
    print('/multi-format (xml) response: ${response.payloadString}');
  } on Exception catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
