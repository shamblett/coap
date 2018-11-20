/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Abstract networking class, allows different implementations for
/// UDP, test etc.
abstract class CoapNetwork {
  /// The internet address
  InternetAddress address;

  /// The port
  int port;

  /// Send, returns the number of bytes sent or 0
  int send(typed.Uint8Buffer data);

  /// Receive, if nothing is received null is returned.
  typed.Uint8Buffer receive();

  /// Bind the socket
  Future<dynamic> bind();

  /// Close the socket
  void close();

  /// Equality, deemed to be equal if the address an port are the same
  @override
  bool operator ==(dynamic other) {
    if (other is CoapNetwork) {
      if (other.port == port && other.address == address) {
        return true;
      }
    }
    return false;
  }

  // Hash code
  @override
  int get hashCode {
    int result = 17;
    result = 37 * result + port.hashCode;
    result = 37 * result + address.hashCode;
    return result;
  }
}
