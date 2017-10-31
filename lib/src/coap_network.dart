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

  /// Send, returns the number of bytes sent or 0
  int send(Datagram data);

  /// Receive, if nothing is received null is returned.
  Datagram receive();
}
