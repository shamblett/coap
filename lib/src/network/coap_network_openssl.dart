/*
 * Package : Coap
 * Author : Sorunome <mail@sorunome.de>,
 *          Jan Romann <jan.romann@uni-bremen.de>
 * Date   : 05/09/2022
 * Copyright :  Jan Romann
 */

import 'dart:io';
import 'dart:typed_data';

import 'package:dtls/dtls.dart';
import 'package:typed_data/typed_data.dart';

import '../event/coap_event_bus.dart';
import '../net/coap_internet_address.dart';
import 'coap_inetwork.dart';

/// DTLS network using OpenSSL
class CoapNetworkOpenSSL implements CoapINetwork {
  /// Initialize with an [address] and a [port].
  ///
  /// This [CoapINetwork] can be configured to be used [withTrustedRoots] and
  /// to [verify] certificate chains. You can also indicate a list of [ciphers],
  /// see the [OpenSSL documentation] for more information on this.
  ///
  /// [OpenSSL documentation]: https://www.openssl.org/docs/man1.1.1/man1/ciphers.html
  CoapNetworkOpenSSL(
    this.address,
    this.port, {
    required final bool verify,
    required final bool withTrustedRoots,
    final String namespace = '',
    final String? ciphers,
  })  : _eventBus = CoapEventBus(namespace: namespace),
        _ciphers = ciphers,
        _verify = verify,
        _withTrustedRoots = withTrustedRoots;

  final CoapEventBus _eventBus;

  void _processFrame(final Uint8List frame) {
    final buff = Uint8Buffer();
    if (frame.isNotEmpty) {
      buff.addAll(frame.toList());
      final rxEvent = CoapDataReceivedEvent(buff, address);
      _eventBus.fire(rxEvent);
    }
  }

  DtlsClientConnection? _dtlsConnection;

  RawDatagramSocket? _socket;

  RawDatagramSocket? get socket => _socket;

  final bool _verify;

  final String? _ciphers;

  final bool _withTrustedRoots;

  @override
  final CoapInternetAddress address;

  @override
  final int port;

  @override
  String get namespace => _eventBus.namespace;

  bool _bound = false;

  @override
  Future<int> send(
    final Uint8Buffer data, [
    final CoapInternetAddress? address,
  ]) async {
    // FIXME: There is currently no way for reconnecting if the connection has
    //        been lost in the meantime

    final bytes = Uint8List.view(data.buffer, data.offsetInBytes, data.length);

    // FIXME: The send method does not return the number of bytes written at
    //       the moment.
    _dtlsConnection?.send(bytes);
    return -1;
  }

  @override
  void receive() {
    _socket?.listen((final event) {
      switch (event) {
        case RawSocketEvent.read:
          final datagram = _socket?.receive();

          if (datagram == null) {
            return;
          }

          _dtlsConnection?.incoming(datagram.data);
          break;
        case RawSocketEvent.closed:
        case RawSocketEvent.readClosed:
        case RawSocketEvent.write:
          break;
      }
    });
    _dtlsConnection?.received.listen(_processFrame);
  }

  @override
  Future<void> bind() async {
    if (_bound) {
      return;
    }
    // Use a port of 0 here as we are a client, this will generate
    // a random source port.
    final bindAddress = address.bind;
    _socket = await RawDatagramSocket.bind(bindAddress, 0);
    _dtlsConnection = DtlsClientConnection(
      context: DtlsClientContext(
        verify: _verify,
        withTrustedRoots: _withTrustedRoots,
        ciphers: _ciphers,
      ),
      hostname: address.address.host,
    );
    receive();
    _dtlsConnection?.outgoing
        .listen((final d) => _socket?.send(d, address.address, port));
    await _dtlsConnection
        ?.connect()
        .timeout(const Duration(seconds: 10), onTimeout: _handleTimeout);
    _bound = true;
  }

  void _handleTimeout() {
    close();
    throw const HandshakeException('Establishing dtls connection timed out');
  }

  @override
  void close() {
    _socket?.close();
    _dtlsConnection?.free();
    _bound = false;
  }
}
