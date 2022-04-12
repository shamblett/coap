/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Abstract networking class, allows different implementations for
/// UDP, test etc.
abstract class CoapINetwork {
  /// The internet address
  CoapInternetAddress? address;

  /// The namespace
  String get namespace;

  /// The port
  int? port;

  /// Send, returns the number of bytes sent or null
  /// if not bound.
  int send(typed.Uint8Buffer data, [CoapInternetAddress? address]);

  /// Starts the receive listener
  void receive();

  /// Bind the network
  Future<void> bind();

  /// Close the socket
  void close();
}
