// ignore_for_file: avoid_types_on_closure_parameters

/*
 * Package : Coap
 * Author : Sorunome <mail@sorunome.de>,
 *          Jan Romann <jan.romann@uni-bremen.de>
 * Date   : 05/09/2022
 * Copyright :  Jan Romann
 */

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dtls/dtls.dart';
import 'package:typed_data/typed_buffers.dart';

import '../coap_message.dart';
import '../event/coap_event_bus.dart';
import 'coap_inetwork.dart';
import 'coap_network_udp.dart';

/// DTLS network using OpenSSL
class CoapNetworkUDPOpenSSL extends CoapNetworkUDP {
  /// Initialize with an [address] and a [port].
  ///
  /// This [CoapINetwork] can be configured to be used [withTrustedRoots] and
  /// to [verify] certificate chains. You can also indicate a list of [ciphers],
  /// see the [OpenSSL documentation] for more information on this.
  ///
  /// [OpenSSL documentation]: https://www.openssl.org/docs/man1.1.1/man1/ciphers.html
  CoapNetworkUDPOpenSSL(
    super.address,
    super.port,
    super.bindAddress, {
    required final bool verify,
    required final bool withTrustedRoots,
    required final List<Uint8List> rootCertificates,
    super.namespace,
    final String? ciphers,
  })  : _ciphers = ciphers,
        _verify = verify,
        _withTrustedRoots = withTrustedRoots,
        _rootCertificates = rootCertificates;

  DtlsClientConnection? _dtlsConnection;

  final List<Uint8List> _rootCertificates;

  final bool _verify;

  final String? _ciphers;

  final bool _withTrustedRoots;

  @override
  void send(final CoapMessage coapMessage) {
    if (isClosed) {
      return;
    }

    final data = coapMessage.toUdpPayload();
    final bytes = Uint8List.view(data.buffer, data.offsetInBytes, data.length);
    _dtlsConnection?.send(bytes);
  }

  @override
  Future<void> init() async {
    if (!isClosed || !shouldReinitialize) {
      return;
    }

    _dtlsConnection = DtlsClientConnection(
      context: DtlsClientContext(
        verify: _verify,
        withTrustedRoots: _withTrustedRoots,
        rootCertificates: _rootCertificates,
        ciphers: _ciphers,
      ),
      hostname: address.host,
    );

    _dtlsConnection?.outgoing.listen(
          (final d) => socket?.send(d, address, port),
      onError: (final Object e, final StackTrace s) =>
          eventBus.fire(CoapSocketErrorEvent(e, s)),
    );

    await bind();
    _receive();

    await _dtlsConnection?.connect().timeout(CoapINetwork.initTimeout);

    isClosed = false;
  }

  @override
  void close() {
    _dtlsConnection?.free();
    super.close();
  }

  void _receive() {
    socket?.listen(
      (final event) {
        switch (event) {
          case RawSocketEvent.read:
            final d = socket?.receive();
            if (d == null) {
              return;
            }
            _dtlsConnection?.incoming(d.data);
            break;
          case RawSocketEvent.closed:
          case RawSocketEvent.readClosed:
          case RawSocketEvent.write:
            break;
        }
      },
      onError: (final Object e, final StackTrace s) =>
          eventBus.fire(CoapSocketErrorEvent(e, s)),
    );
    _dtlsConnection?.received.listen(
      (final frame) {
        final message =
            CoapMessage.fromUdpPayload(Uint8Buffer()..addAll(frame));
        eventBus.fire(CoapMessageReceivedEvent(message, address));
      },
      onError: (final Object e, final StackTrace s) =>
          eventBus.fire(CoapSocketErrorEvent(e, s)),
      onDone: () {
        isClosed = true;
        Timer.periodic(CoapINetwork.reinitPeriod, (final timer) async {
          try {
            socket?.close();
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
