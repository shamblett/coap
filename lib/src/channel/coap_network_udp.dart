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

  final CoapILogger _log = CoapLogManager().logger;

  final CoapEventBus _eventBus = CoapEventBus();

  /// The internet address
  @override
  CoapInternetAddress address;

  /// The port to use for sending.
  @override
  int port;

  @override
  final StreamController<List<int>> _data =
      StreamController<List<int>>.broadcast();

  RawDatagramSocket _socket;
  bool _bound = false;

  /// The incoming data stream, call receive() to instigate
  /// data reception
  @override
  Stream<List<int>> get data => _data.stream;

  /// UDP socket
  RawDatagramSocket get socket => _socket;

  @override
  int send(typed.Uint8Buffer data) {
    try {
      if (_bound) {
        _socket?.send(data.toList(), address.address, port);
      }
    } on SocketException catch (e) {
      _log.error(
          'CoapNetworkUDP Recieve - severe error - socket exception : $e');
    } on Exception catch (e) {
      _log.error('CoapNetworkUDP Send - severe error : $e');
    }
    return -1;
  }

  @override
  void receive() {
    try {
      _socket?.listen((RawSocketEvent e) {
        switch (e) {
          case RawSocketEvent.read:
            final d = _socket?.receive();
            if (d != null) {
              final buff = typed.Uint8Buffer();
              if (d.data != null && d.data.isNotEmpty) {
                _data.add(d.data.toList());
                buff.addAll(d.data.toList());
                final rxEvent = CoapDataReceivedEvent(buff, address);
                _eventBus.fire(rxEvent);
              }
            }
            break;
          case RawSocketEvent.closed:
            close();
        }
      });
    } on SocketException catch (e) {
      _log.error(
          'CoapNetworkUDP Recieve - severe error - socket exception : $e');
    } on Exception catch (e) {
      _log.error(
          'CoapNetworkUDP Recieve - severe error - unknown exception: $e');
    }
  }

  @override
  void bind() {
    if (_bound) {
      return;
    }
    try {
      // Use a port of 0 here as we are a client, this will generate
      // a random source port.
      final bindAddress = address.bind;
      _log.info('CoapNetworkUDP - binding to $bindAddress');
      RawDatagramSocket.bind(bindAddress, 0).then((RawDatagramSocket socket) {
        _socket = socket;
        receive();
        _bound = true;
      });
    } on SocketException catch (e) {
      _log.error('CoapNetworkUDP Recieve - severe error - socket exception '
          'failed to bind, address ${address.address.host}, '
          'port $port with exception $e: $e');
    } on Exception catch (e) {
      _log.error('CoapNetworkUDP - severe error - Failed to bind, '
          'address ${address.address.host}, port $port with exception $e');
    }
  }

  @override
  void close() {
    _log.info('Network UDP - closing ${address.address.host}, port $port');
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
    var result = 17;
    result = 37 * result + port.hashCode;
    result = 37 * result + address.hashCode;
    return result;
  }
}
