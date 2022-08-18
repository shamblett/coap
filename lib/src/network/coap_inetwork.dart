/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

import 'dart:io';

import '../coap_config.dart';
import '../coap_constants.dart';
import '../coap_message.dart';
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
/// UDP, TCP, test etc.
abstract class CoapINetwork {
  /// The initialization timeout
  static const Duration initTimeout = Duration(seconds: 10);

  /// The reinit period for open connections
  static Duration reinitPeriod = initTimeout + const Duration(seconds: 2);

  /// The local address
  InternetAddress get bindAddress;

  /// The remote address
  InternetAddress get address;

  /// The remote port
  int get port;

  /// If the underlying socket is closed
  bool get isClosed;

  /// Bind (UDP) or connect (TCP) to the network and listen
  Future<void> init();

  /// Sends a [coapMessage] over the socket.
  void send(final CoapMessage coapMessage);

  /// Close the socket
  void close();

  /// Creates a new CoapINetwork from a given URI
  static CoapINetwork fromUri(
    final Uri uri, {
    required final InternetAddress address,
    required final DefaultCoapConfig config,
    final String namespace = '',
    final InternetAddress? bindAddress,
    final PskCredentialsCallback? pskCredentialsCallback,
    final EcdsaKeys? ecdsaKeys,
  }) {
    final defaultBindAddress = address.type == InternetAddressType.IPv4
        ? InternetAddress.anyIPv4
        : InternetAddress.anyIPv6;
    final port = uri.port > 0 ? uri.port : null;
    switch (uri.scheme) {
      case CoapConstants.uriScheme:
        return CoapNetworkUDP(
          address,
          port ?? config.defaultPort,
          bindAddress ?? defaultBindAddress,
          namespace: namespace,
        );
      case CoapConstants.secureUriScheme:
        switch (config.dtlsBackend) {
          case DtlsBackend.TinyDtls:
            if (pskCredentialsCallback == null && ecdsaKeys == null) {
              throw CoapCredentialsException(
                'A PSK credentials callback and/or ECDSA keys have been expected '
                'to use CoAPS, but neither have been found!',
              );
            }
            return CoapNetworkUDPTinyDtls(
              address,
              port ?? config.defaultSecurePort,
              bindAddress ?? defaultBindAddress,
              config.tinyDtlsInstance,
              namespace: namespace,
              pskCredentialsCallback: pskCredentialsCallback,
              ecdsaKeys: ecdsaKeys,
            );
          case DtlsBackend.OpenSsl:
            return CoapNetworkUDPOpenSSL(
              address,
              port ?? config.defaultSecurePort,
              bindAddress ?? defaultBindAddress,
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
      default:
        throw UnsupportedProtocolException(uri.scheme);
    }
  }
}
