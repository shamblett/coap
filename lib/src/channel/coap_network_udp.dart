/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

class CoapNetworkUDP extends CoapNetwork {
  /// UDP socket
  RawDatagramSocket _socket;

  RawDatagramSocket get socket => _socket;

  /// Send, returns the number of bytes sent or 0
  int send(Datagram data) {
    return _socket.send(data.data, data.address, data.port);
  }

  /// Receive, if nothing is received null is returned.
  Datagram receive() {
    return _socket.receive();
  }
}
