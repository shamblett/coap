/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// UDP network
class CoapNetworkUDP implements CoapINetwork {
  /// Initialize with an address and a port
  CoapNetworkUDP(this.address, this.port);

  /// The internet address
  @override
  InternetAddress address;

  /// The port
  @override
  int port;

  @override
  StreamController<List<int>> _data = StreamController<List<int>>.broadcast();

  RawDatagramSocket _socket;
  bool _bound = false;

  /// The incoming data stream, call receive() to instifgate
  /// data reception
  @override
  Stream<List<int>> get data => _data.stream;

  /// UDP socket
  RawDatagramSocket get socket => _socket;

  @override
  int send(typed.Uint8Buffer data) =>
      _bound ? _socket?.send(data.toList(), address, port) : null;

  @override
  void receive() {
    _socket?.listen((RawSocketEvent e) {
      switch (e) {
        case RawSocketEvent.read:
          final Datagram d = _socket.receive();
          if (d != null) {
            _data.add(d.data.toList());
          }
          break;
        case RawSocketEvent.closed:
          close();
      }
    });
  }

  @override
  Future<dynamic> bind() async {
    final Completer<dynamic> completer = Completer<dynamic>();
    if (_bound) {
      return null;
    }
    try {
      _socket = await RawDatagramSocket.bind(address.host, port);
      _bound = true;
      completer.complete();
    } on Exception catch (e) {
      print('Not bound - exception raised $e');
      completer.completeError(e);
    }
    return completer.future;
  }

  @override
  void close() {
    _socket.close();
    _data.close();
  }

  /// Equality, deemed to be equal if the address an port are the same
  @override
  bool operator ==(dynamic other) {
    if (other is CoapNetworkUDP) {
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
