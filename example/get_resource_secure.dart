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
 * You need to have OpenSSL available on your system to be able to run this
 * example. See the README file or the dtls2 documentation for more information.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:coap/coap.dart';

final identity = Uint8List.fromList(utf8.encode('Client_identity'));
final preSharedKey = Uint8List.fromList(utf8.encode('secretPSK'));

final pskCredentials =
    PskCredentials(identity: identity, preSharedKey: preSharedKey);

PskCredentials pskCredentialsCallback(
  final Uint8List indentity,
  final Uri uri,
) =>
    pskCredentials;

class DtlsConfig extends DefaultCoapConfig {
  @override
  String? get dtlsCiphers => 'PSK-AES128-CCM8';
}

FutureOr<void> main() async {
  final conf = DtlsConfig();
  final uri = Uri(
    scheme: 'coaps',
    host: 'californium.eclipseprojects.io',
    port: conf.defaultSecurePort,
  );
  final client = CoapClient(
    config: conf,
    pskCredentialsCallback: pskCredentialsCallback,
  );

  try {
    print('Sending get /test to ${uri.host}');
    var response = await client.get(uri.replace(path: 'test'));
    print('/test response: ${response.payloadString}');

    print('Sending get /multi-format (text) to ${uri.host}');
    response = await client.get(uri.replace(path: 'multi-format'));
    print('/multi-format (text) response: ${response.payloadString}');

    print('Sending get /multi-format (xml) to ${uri.host}');
    response = await client.get(
      uri.replace(path: 'multi-format'),
      accept: CoapMediaType.applicationXml,
    );
    print('/multi-format (xml) response: ${response.payloadString}');
  } on Exception catch (e) {
    print('CoAP encountered an exception: $e');
  }

  await client.close();
}
