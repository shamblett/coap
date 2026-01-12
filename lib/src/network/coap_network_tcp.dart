/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:io';

import 'package:typed_data/typed_data.dart';

import '../coap_message.dart';
import '../event/coap_event_bus.dart';
import 'coap_inetwork.dart';

/// TCP network
class CoapNetworkTCP implements CoapINetwork {
  final CoapEventBus eventBus;

  @override
  final InternetAddress address;

  @override
  final int port;

  @override
  final InternetAddress bindAddress;

  final bool isTls;

  @override
  bool isClosed = true;

  bool _shouldReinitialize = true;

  final SecurityContext? _tlsContext;

  Socket? _socket;

  Socket? get socket => _socket;

  /// Initialize with an address and a port
  CoapNetworkTCP(
    this.address,
    this.port,
    this.bindAddress, {
    this.isTls = false,
    final SecurityContext? tlsContext,
    final String namespace = '',
  }) : eventBus = CoapEventBus(namespace: namespace),
       _tlsContext = tlsContext;

  @override
  void send(final CoapMessage message, [final InternetAddress? _]) {
    if (isClosed) {
      return;
    }

    _socket?.add(message.toTcpPayload());
  }

  @override
  Future<void> init() async {
    if (!isClosed || !_shouldReinitialize) {
      return;
    }

    eventBus.fire(CoapSocketInitEvent());

    _socket =
        isTls
            ? await SecureSocket.connect(
              address,
              port,
              context: _tlsContext,
              timeout: CoapINetwork.initTimeout,
            )
            : await Socket.connect(
              address,
              port,
              sourceAddress: bindAddress,
              timeout: CoapINetwork.initTimeout,
            );
    _receive();

    isClosed = false;
  }

  @override
  void close() {
    _shouldReinitialize = false;
    _socket?.close();
    isClosed = true;
  }

  void _receive() {
    socket?.listen(
      (final data) {
        final message = CoapMessage.fromTcpPayload(Uint8Buffer()..addAll(data));
        eventBus.fire(CoapMessageReceivedEvent(message, address));
      },
      onError:
          (final Object e, final StackTrace s) =>
              eventBus.fire(CoapSocketErrorEvent(e, s)),
      // Socket stream is done and can no longer be listened to
      onDone: () {
        isClosed = true;
        Timer.periodic(CoapINetwork.reinitPeriod, (final timer) async {
          try {
            await init();
            timer.cancel();
          } on Exception catch (_) {
            // Ignore errors, retry until successful
          }
        });
      },
    );
  }
}
