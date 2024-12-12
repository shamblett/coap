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
import 'package:coap/coap.dart';

final identity = utf8.encode('Client_identity');
final preSharedKey = utf8.encode('secretPSK');

final pskCredentials =
    PskCredentials(identity: identity, preSharedKey: preSharedKey);

PskCredentials pskCredentialsCallback(final String? identityHint) =>
    pskCredentials;

class DtlsConfig extends DefaultCoapConfig {
  @override
  String? get dtlsCiphers => 'PSK-AES128-CCM8';

  @override
  // Since TLS_PSK_WITH_AES_128_CCM_8 (also known as PSK-AES128-CCM8 in OpenSSL)
  // is considered insecure in more recent versions of OpenSSL, we reduce the
  // security level here, as TLS_PSK_WITH_AES_128_CCM_8 is the mandatory cipher
  // suite that CoAP implementations must support when using DTLS in PSK mode
  // (see section 9.1.3.1 of RFC 7252).
  int? get openSslSecurityLevel => 0;
}

FutureOr<void> main() async {
  final conf = DtlsConfig();
  final baseUri = Uri(
    scheme: 'coaps',
    host: 'californium.eclipseprojects.io',
    port: conf.defaultSecurePort,
  );
  final client = CoapClient(
    baseUri,
    config: conf,
    pskCredentialsCallback: pskCredentialsCallback,
  );

  try {
    print('Sending get /test to ${baseUri.host}');
    var response = await client.get(Uri(path: 'test'));
    print('/test response: ${response.payloadString}');

    print('Sending get /multi-format (text) to ${baseUri.host}');
    response = await client.get(Uri(path: 'multi-format'));
    print('/multi-format (text) response: ${response.payloadString}');

    print('Sending get /multi-format (xml) to ${baseUri.host}');
    response = await client.get(
      Uri(path: 'multi-format'),
      accept: CoapMediaType.applicationXml,
    );
    print('/multi-format (xml) response: ${response.payloadString}');
  } on Exception catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
