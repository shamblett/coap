/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

import 'dart:io';

import 'package:typed_data/typed_data.dart';

import '../coap_message.dart';
import '../event/coap_event_bus.dart';
import 'coap_inetwork.dart';

/// UDP network
class CoapNetworkUDP implements CoapINetwork {
  @override
  final InternetAddress address;

  @override
  final int port;

  @override
  final InternetAddress bindAddress;

  final CoapEventBus eventBus;

  @override
  bool isClosed = true;

  bool _shouldReinitialize = true;

  RawDatagramSocket? _socket;

  bool get shouldReinitialize => _shouldReinitialize;

  RawDatagramSocket? get socket => _socket;

  /// Initialize with an address and a port
  CoapNetworkUDP(
    this.address,
    this.port,
    this.bindAddress, {
    final String namespace = '',
  }) : eventBus = CoapEventBus(namespace: namespace);

  @override
  void send(final CoapMessage coapMessage) {
    if (isClosed) {
      return;
    }

    _socket!.send(
      coapMessage.toUdpPayload(),
      coapMessage.destination ?? address,
      port,
    );
  }

  @override
  Future<void> init() async {
    if (!isClosed || !shouldReinitialize) {
      return;
    }

    await bind();
    _receive();

    isClosed = false;
  }

  @override
  void close() {
    _shouldReinitialize = false;
    _socket?.close();
    isClosed = true;
  }

  Future<void> bind() async {
    eventBus.fire(CoapSocketInitEvent());

    // Use port 0 to generate a random source port
    _socket = await RawDatagramSocket.bind(bindAddress, 0);
  }

  void _receive() {
    _socket?.listen(
      (final e) {
        switch (e) {
          case RawSocketEvent.read:
            final d = _socket?.receive();
            if (d == null) {
              return;
            }
            // d.address can differ from address with multicast
            final message = CoapMessage.fromUdpPayload(
              Uint8Buffer()..addAll(d.data),
              'coap',
            );
            eventBus.fire(CoapMessageReceivedEvent(message, d.address));
            break;
          // When we manually closed the socket (no need to do anything)
          case RawSocketEvent.closed:
          // Never occurs for UDP (socket cannot be closed by a remote peer)
          case RawSocketEvent.readClosed:
          case RawSocketEvent.write:
            break;
        }
      },
      // ignore: avoid_types_on_closure_parameters
      onError:
          (final Object e, final StackTrace s) =>
              eventBus.fire(CoapSocketErrorEvent(e, s)),
      // Socket stream is done and can no longer be listened to
      onDone: () {
        isClosed = true;
        init();
      },
    );
  }
}
