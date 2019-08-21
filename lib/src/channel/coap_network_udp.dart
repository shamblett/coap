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

  static CoapILogger _log = CoapLogManager('console').logger;

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
  int send(typed.Uint8Buffer data) {
    if (_bound) {
      _socket?.send(data.toList(), address, port);
    }
    return -1;
  }

  @override
  void receive() {
    _socket?.listen((RawSocketEvent e) {
      switch (e) {
        case RawSocketEvent.read:
          final Datagram d = _socket?.receive();
          if (d != null) {
            typed.Uint8Buffer buff = typed.Uint8Buffer();
            _data.add(d.data.toList());
            buff.addAll(d.data.toList());
            final CoapDataReceivedEvent rxEvent =
            CoapDataReceivedEvent(buff, address);
            clientEventBus.fire(rxEvent);
          }
          break;
        case RawSocketEvent.closed:
          close();
      }
    });
  }

  @override
  void bind() {
    if (_bound) {
      return null;
    }
    try {
      RawDatagramSocket.bind(address.host, port)
          .then((RawDatagramSocket socket) {
        _socket = socket;
        receive();
        _bound = true;
      });
    } on Exception catch (e) {
      _log.error(
          'Failed to bind, address ${address
              .host}, port $port with exception $e');
    }
  }

  @override
  void close() {
    _log.info('Closing ${address.host}, port $port');
    _socket?.close();
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
