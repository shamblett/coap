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
  CoapUDPChannel(this._address, this._port, this.uriScheme,
      {required String namespace, required this.config}) {
    _eventBus = CoapEventBus(namespace: namespace);
    final socket = CoapNetworkManagement.getNetwork(
        address!, _port, CoapConstants.uriScheme,
        namespace: namespace, config: config);
    _socket = socket;
  }

  final String uriScheme;

  final int _port;

  final DefaultCoapConfig config;

  @override
  int get port => _port;
  final CoapInternetAddress? _address;

  @override
  CoapInternetAddress? get address => _address;
  late CoapINetwork _socket;

  final typed.Uint8Buffer _buff = typed.Uint8Buffer();

  late final CoapEventBus _eventBus;

  @override
  Future<void> start() async {
    _socket.port = _port;
    _socket.address = _address;
    await _socket.bind();
  }

  @override
  void stop() {
    CoapNetworkManagement.removeNetwork(_socket);
    _socket.close();
  }

  @override
  Future<void> send(typed.Uint8Buffer data,
      [CoapInternetAddress? address]) async {
    _socket.send(data, address);
  }

  @override
  void receive() {
    final rxEvent = CoapDataReceivedEvent(_buff, _address);
    _eventBus.fire(rxEvent);
    _buff.clear();
  }
}
