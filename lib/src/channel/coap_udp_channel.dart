/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Channel via UDP protocol.
class CoapUDPChannel extends CoapIChannel {
  /// Initialise with a specific address and port
  CoapUDPChannel(this._eventBus, this._address, this._port) {
    final socket = CoapNetworkManagement.getNetwork(address!, _port);
    _socket = socket as CoapNetworkUDP;
  }

  final int _port;

  @override
  int get port => _port;
  final CoapInternetAddress? _address;

  @override
  CoapInternetAddress? get address => _address;
  late CoapNetworkUDP _socket;

  final typed.Uint8Buffer _buff = typed.Uint8Buffer();

  final CoapEventBus _eventBus;

  @override
  Future<void> start() async {
    _socket.port = _port;
    _socket.address = _address;
    await _socket.bind();
  }

  @override
  void stop() {
    _socket.close();
  }

  @override
  Future<void> send(typed.Uint8Buffer data,
      [CoapInternetAddress? address]) async {
    if (_socket.socket != null) {
      _socket.send(data);
    }
  }

  @override
  void receive() {
    final rxEvent = CoapDataReceivedEvent(_buff, _address);
    _eventBus.fire(rxEvent);
    _buff.clear();
  }
}
