/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

import 'dart:io';

import 'package:typed_data/typed_data.dart';

import '../event/coap_event_bus.dart';
import '../net/coap_internet_address.dart';
import 'coap_inetwork.dart';

/// UDP network
class CoapNetworkUDP implements CoapINetwork {
  /// Initialize with an address and a port
  CoapNetworkUDP(this.address, this.port, {final String namespace = ''})
      : _eventBus = CoapEventBus(namespace: namespace);

  CoapNetworkUDP.from(
    final CoapNetworkUDP src, {
    required final String namespace,
  })  : address = src.address,
        port = src.port,
        _eventBus = CoapEventBus(namespace: namespace),
        _socket = src.socket,
        _bound = src.bound;

  final CoapEventBus _eventBus;

  @override
  final CoapInternetAddress address;

  @override
  final int port;

  @override
  String get namespace => _eventBus.namespace;

  /// UDP socket
  RawDatagramSocket? _socket;
  RawDatagramSocket? get socket => _socket;

  bool _bound = false;
  bool get bound => _bound;

  @override
  Future<int> send(
    final Uint8Buffer data, [
    final CoapInternetAddress? address,
  ]) async {
    if (_bound) {
      _socket?.send(
        data.toList(),
        address?.address ?? this.address.address,
        port,
      );
    }
    return -1;
  }

  @override
  void receive() {
    _socket?.listen((final e) {
      switch (e) {
        case RawSocketEvent.read:
          final d = _socket?.receive();
          if (d != null) {
            final buff = Uint8Buffer();
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
          break;
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
    _socket = await RawDatagramSocket.bind(address.bind, 0);
    _bound = true;
    receive();
  }

  @override
  void close() {
    _socket?.close();
  }
}
