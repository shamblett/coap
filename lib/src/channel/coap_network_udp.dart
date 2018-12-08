/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// UDP network
class CoapNetworkUDP extends CoapNetwork {
  /// Initialize with an address and a port
  CoapNetworkUDP(this._address, this._port);

  InternetAddress _address;

  @override
  InternetAddress get address => _address;

  int _port = 0;

  @override
  int get port => _port;

  // Indicates if the socket is/being bound
  bool _bound = false;
  int _binding = 0;

  /// UDP socket
  RawDatagramSocket _socket;

  /// Socket
  RawDatagramSocket get socket => _socket;

  @override
  int send(typed.Uint8Buffer data) {
    print('SJH - UDP - sending ${data.length} bytes');
    final int bytesSent = _socket?.send(data.toList(), address, port);
    print('SJH - UDP - sending - sent $bytesSent bytes');
    return bytesSent;
  }

  @override
  typed.Uint8Buffer receive() {
    print('SJH - UDP - receiving');
    final Datagram rec = _socket.receive();
    if (rec == null) {
      print('SJH - UDP - null recieve');
      return null;
    }
    if (rec.data.isEmpty) {
      print('SJH - UDP - null length');
      return null;
    }
    print('SJH - UDP - received ${rec.data}');
    return typed.Uint8Buffer()..addAll(rec.data);
  }

  @override
  Future<dynamic> bind() async {
    final Completer<dynamic> completer = Completer<dynamic>();
    if (_binding > 0) {
      return null;
    }
    if (!_bound && _binding == 0) {
      _binding++;
      print('SJH - UDP - binding');
      try {
        _socket = await RawDatagramSocket.bind(address.host, port);
        _socket.listen((RawSocketEvent e) {
          if (e == RawSocketEvent.read) {
            receive();
          }
        });
        _bound = true;
        _binding = 0;
        completer.complete();
      } on Exception catch (e) {
        print('Not bound - exception raised $e');
        completer.completeError(e);
      }
    }
    return completer.future;
  }

  @override
  void close() {
    _socket.close();
  }
}
