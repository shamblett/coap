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
  CoapInternetAddress address;

  /// The port
  int port;

  final StreamController<List<int>> _data =
      StreamController<List<int>>.broadcast();

  /// Send, returns the number of bytes sent or null
  /// if not bound.
  int send(typed.Uint8Buffer data);

  /// Starts the receive listener
  void receive();

  /// The incoming data stream, call receive() to instifgate
  /// data reception
  Stream<List<int>> get data => _data.stream;

  /// Bind the network
  void bind();

  /// Close the socket
  void close();
}
