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
  CoapNetworkUDP(this.address, this.port, {String namespace = ''}) {
    _eventBus = CoapEventBus(namespace: namespace);
  }

  CoapNetworkUDP.from(CoapNetworkUDP src, {required String namespace})
      : address = src.address,
        port = src.port,
        _eventBus = CoapEventBus(namespace: namespace),
        _socket = src.socket,
        _bound = src.bound;

  late final CoapEventBus _eventBus;

  /// The internet address
  @override
  CoapInternetAddress? address;

  /// The port to use for sending.
  @override
  int port;

  /// The namespace to use
  @override
  String get namespace => _eventBus.namespace;

  /// UDP socket
  RawDatagramSocket? _socket;
  RawDatagramSocket? get socket => _socket;

  bool _bound = false;
  bool get bound => _bound;

  @override
  int send(typed.Uint8Buffer data, [CoapInternetAddress? address]) {
    if (_bound) {
      _socket?.send(
          data.toList(), address?.address ?? this.address!.address, port);
    }
    return -1;
  }

  @override
  void receive() {
    _socket?.listen((RawSocketEvent e) {
      switch (e) {
        case RawSocketEvent.read:
          final d = _socket?.receive();
          if (d != null) {
            final buff = typed.Uint8Buffer();
            if (d.data.isNotEmpty) {
              buff.addAll(d.data.toList());
              final coapAddress =
                  CoapInternetAddress(d.address.type, d.address);
              _eventBus.fire(CoapDataReceivedEvent(buff, coapAddress));
            }
          }
          break;
        case RawSocketEvent.closed:
        case RawSocketEvent.readClosed:
          close();
          break;
        case RawSocketEvent.write:
      }
    });
  }

  @override
  Future<void> bind() async {
    if (_bound) {
      return;
    }
    // Use a port of 0 here as we are a client, this will generate
    // a random source port.
    _socket = await RawDatagramSocket.bind(address!.bind, 0);
    _bound = true;
    receive();
  }

  @override
  void close() {
    _socket?.close();
  }
}
