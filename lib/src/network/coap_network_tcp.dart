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
  /// Initialize with an address and a port
  CoapNetworkTCP(
    this.address,
    this.port,
    this.bindAddress, {
    this.isTls = false,
    final SecurityContext? tlsContext,
    final String namespace = '',
  })  : eventBus = CoapEventBus(namespace: namespace),
        _tlsContext = tlsContext;

  final CoapEventBus eventBus;

  final InternetAddress address;

  final int port;

  final InternetAddress bindAddress;

  bool _shouldReinitialize = true;

  final bool isTls;

  String get _scheme => isTls ? 'coaps+tcp' : 'coap+tcp';

  final SecurityContext? _tlsContext;

  Socket? _socket;
  Socket? get socket => _socket;

  @override
  bool isClosed = true;

  void send(
    final CoapMessage message,
    final InternetAddress address,
    final int port,
  ) {
    if (isClosed) {
      return;
    }

    _socket?.add(message.toTcpPayload());
  }

  // TODO(JKRhb): Rework initialization
  Future<void> init() async {
    if (!isClosed || !_shouldReinitialize) {
      return;
    }

    eventBus.fire(CoapSocketInitEvent());

    if (isTls) {
      _socket = await SecureSocket.connect(
        address,
        port,
        context: _tlsContext,
        timeout: CoapINetwork.initTimeout,
      );
    } else {
      _socket = await Socket.connect(
        address,
        port,
        sourceAddress: bindAddress,
        timeout: CoapINetwork.initTimeout,
      );
    }
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
        // TODO(JKRhb): Update once actually implementing TCP
        eventBus.fire(
          CoapMessageReceivedEvent(
            message,
            address,
            port,
            scheme: _scheme,
          ),
        );
      },
      // ignore: avoid_types_on_closure_parameters
      onError: (final Object e, final StackTrace s) =>
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

  @override
  void sendMessage(final CoapMessage coapRequest, final Uri uri) {
    // TODO(JKRhb): implement sendRequest
  }
}
