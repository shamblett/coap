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

  int send(typed.Uint8Buffer data) {
    return _socket.send(data.toList(), address, port);
  }

  typed.Uint8Buffer receive() {
    final Datagram rec = _socket.receive();
    if (rec == null) {
      return null;
    }
    if (rec.data.length == 0) {
      return null;
    }
    return new typed.Uint8Buffer()
      ..addAll(rec.data);
  }

  FutureOr bind() async {
    final Completer completer = new Completer();
    RawDatagramSocket.bind(address.host, port)
      ..then((socket) {
        _socket = socket;
        completer.complete;
      });
    return completer.future;
  }

  void close() {
    _socket.close();
  }
}
