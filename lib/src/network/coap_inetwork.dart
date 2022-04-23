/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// This [Exception] is thrown when an unsupported URI scheme is encountered.
class UnsupportedProtocolException implements Exception {
  /// The error message of this [Exception].
  String get message => 'Unsupported URI scheme $uriScheme encountered.';

  /// The unsupported Uri Scheme that was encountered.
  final String uriScheme;

  /// Constructor.
  UnsupportedProtocolException(this.uriScheme);
}

/// Abstract networking class, allows different implementations for
/// UDP, test etc.
abstract class CoapINetwork {
  /// The internet address
  CoapInternetAddress? address;

  /// The namespace
  String get namespace;

  /// The port
  abstract int port;

  /// Send, returns the number of bytes sent or null
  /// if not bound.
  int send(typed.Uint8Buffer data, [CoapInternetAddress? address]);

  /// Starts the receive listener
  void receive();

  /// Bind the network
  Future<void> bind();

  /// Close the socket
  void close();

  /// Creates a new CoapINetwork from a given URI
  static CoapINetwork fromUri(
    Uri uri, {
    required CoapInternetAddress? address,
    required DefaultCoapConfig config,
    String namespace = '',
  }) {
    int? port = uri.port > 0 ? uri.port : null;
    switch (uri.scheme) {
      case CoapConstants.uriScheme:
        return CoapNetworkUDP(address, port ?? config.defaultPort,
            namespace: namespace);
      default:
        throw UnsupportedProtocolException(uri.scheme);
    }
  }
}
