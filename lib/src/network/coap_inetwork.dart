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
  /// The unsupported Uri Scheme that was encountered.
  final String uriScheme;

  /// Constructor.
  UnsupportedProtocolException(this.uriScheme);

  @override
  String toString() =>
      '$runtimeType: Unsupported URI scheme $uriScheme encountered.';
}

/// This [Exception] is thrown when Credentials for secure CoAP communication
/// are missing.
class CoapCredentialsException implements Exception {
  final String _message;

  /// Create a new [Exception] that prints out the given [_message].
  CoapCredentialsException(this._message);

  @override
  String toString() => '$runtimeType: $_message';
}

/// This [Exception] is thrown when a DTLS related problem occurs.
class CoapDtlsException implements Exception {
  final String _message;

  /// Create a new [Exception] that prints out the given [_message].
  CoapDtlsException(this._message);

  @override
  String toString() => '$runtimeType: $_message';
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
  Future<int> send(
    final Uint8Buffer data, [
    final CoapInternetAddress? address,
  ]);

  /// Starts the receive listener
  void receive();

  /// Bind the network
  Future<void> bind();

  /// Close the socket
  void close();

  /// Creates a new CoapINetwork from a given URI
  static CoapINetwork fromUri(
    final Uri uri, {
    required final CoapInternetAddress address,
    required final DefaultCoapConfig config,
    final String namespace = '',
    final PskCredentialsCallback? pskCredentialsCallback,
    final EcdsaKeys? ecdsaKeys,
  }) {
    final port = uri.port > 0 ? uri.port : null;
    switch (uri.scheme) {
      case CoapConstants.uriScheme:
        return CoapNetworkUDP(
          address,
          port ?? config.defaultPort,
          namespace: namespace,
        );
      case CoapConstants.secureUriScheme:
        return _determineDtlsNetwork(
          address,
          port,
          config,
          namespace: namespace,
          pskCredentialsCallback: pskCredentialsCallback,
          ecdsaKeys: ecdsaKeys,
        );
      default:
        throw UnsupportedProtocolException(uri.scheme);
    }
  }

  /// Determines which [CoapINetwork] to use for secure communication using
  /// DTLS.
  static CoapINetwork _determineDtlsNetwork(
    final CoapInternetAddress address,
    final int? port,
    final DefaultCoapConfig config, {
    final String namespace = '',
    final PskCredentialsCallback? pskCredentialsCallback,
    final EcdsaKeys? ecdsaKeys,
  }) {
    switch (config.dtlsBackend) {
      case DtlsBackend.TinyDtls:
        if (pskCredentialsCallback != null || ecdsaKeys != null) {
          return CoapNetworkTinyDtls(
            address,
            port ?? config.defaultSecurePort,
            config.tinyDtlsInstance,
            namespace: namespace,
            pskCredentialsCallback: pskCredentialsCallback,
            ecdsaKeys: ecdsaKeys,
          );
        }

        throw CoapCredentialsException(
          'A PSK credentials callback and/or ECDSA keys have been expected '
          'to use CoAPS, but neither have been found!',
        );
      case DtlsBackend.OpenSsl:
        return CoapNetworkOpenSSL(
          address,
          port ?? config.defaultSecurePort,
          verify: config.dtlsVerify,
          withTrustedRoots: config.dtlsWithTrustedRoots,
          ciphers: config.dtlsCiphers,
        );
      case null:
        throw CoapDtlsException(
          'Encountered a coaps:// URI scheme but no DTLS backend has been '
          'enabled in the config.',
        );
    }
  }
}
