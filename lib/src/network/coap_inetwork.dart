/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

import 'package:typed_data/typed_data.dart';

import '../coap_config.dart';
import '../coap_constants.dart';
import '../net/coap_internet_address.dart';
import 'coap_network_openssl.dart';
import 'coap_network_tinydtls.dart';
import 'coap_network_udp.dart';
import 'credentials/ecdsa_keys.dart';
import 'credentials/psk_credentials.dart';

/// This [Exception] is thrown when an unsupported URI scheme is encountered.
class UnsupportedProtocolException implements Exception {
  /// The error message of this [Exception].
  String get message => 'Unsupported URI scheme $uriScheme encountered.';

  /// The unsupported Uri Scheme that was encountered.
  final String uriScheme;

  /// Constructor.
  UnsupportedProtocolException(this.uriScheme);
}

/// This [Exception] is thrown when Credentials for secure CoAP communication
/// are missing.
class CoapCredentialsException implements Exception {
  /// The error message of this [Exception].
  final String message;

  /// Constructor.
  CoapCredentialsException(this.message);
}

/// This [Exception] is thrown when a DTLS related problem occurs.
class CoapDtlsException implements Exception {
  /// The error message of this [Exception].
  final String message;

  /// Constructor.
  CoapDtlsException(this.message);
}

/// Abstract networking class, allows different implementations for
/// UDP, test etc.
abstract class CoapINetwork {
  /// The internet address
  CoapInternetAddress get address;

  /// The namespace
  String get namespace;

  /// The port
  int get port;

  /// Send, returns the number of bytes sent or null
  /// if not bound.
  Future<int> send(Uint8Buffer data, [CoapInternetAddress? address]);

  /// Starts the receive listener
  void receive();

  /// Bind the network
  Future<void> bind();

  /// Close the socket
  void close();

  /// Creates a new CoapINetwork from a given URI
  static CoapINetwork fromUri(
    Uri uri, {
    required CoapInternetAddress address,
    required DefaultCoapConfig config,
    String namespace = '',
    PskCredentialsCallback? pskCredentialsCallback,
    EcdsaKeys? ecdsaKeys,
  }) {
    int? port = uri.port > 0 ? uri.port : null;
    switch (uri.scheme) {
      case CoapConstants.uriScheme:
        return CoapNetworkUDP(address, port ?? config.defaultPort,
            namespace: namespace);
      case CoapConstants.secureUriScheme:
        return _determineDtlsNetwork(address, port, config,
            namespace: namespace,
            pskCredentialsCallback: pskCredentialsCallback,
            ecdsaKeys: ecdsaKeys);
      default:
        throw UnsupportedProtocolException(uri.scheme);
    }
  }

  /// Determines which [CoapINetwork] to use for secure communication using
  /// DTLS.
  static CoapINetwork _determineDtlsNetwork(
    CoapInternetAddress address,
    int? port,
    DefaultCoapConfig config, {
    String namespace = '',
    PskCredentialsCallback? pskCredentialsCallback,
    EcdsaKeys? ecdsaKeys,
  }) {
    port = port ?? config.defaultSecurePort;

    switch (config.dtlsBackend) {
      case DtlsBackend.TinyDtls:
        if ((pskCredentialsCallback != null || ecdsaKeys != null)) {
          return CoapNetworkTinyDtls(address, port, config.tinyDtlsInstance,
              namespace: namespace,
              pskCredentialsCallback: pskCredentialsCallback,
              ecdsaKeys: ecdsaKeys);
        }

        throw CoapCredentialsException(
            "A PSK credentials callback and/or ECDSA keys have been expected "
            "to use CoAPS, but neither have been found!");
      case DtlsBackend.OpenSsl:
        return CoapNetworkOpenSSL(address, port,
            verify: config.dtlsVerify,
            withTrustedRoots: config.dtlsWithTrustedRoots,
            ciphers: config.dtlsCiphers);
      default:
        throw CoapDtlsException(
            "Encountered a coaps:// URI scheme but no DTLS backend has been "
            "enabled in the config.");
    }
  }
}
