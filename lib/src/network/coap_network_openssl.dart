// ignore_for_file: avoid_types_on_closure_parameters

/*
 * Package : Coap
 * Author : Sorunome <mail@sorunome.de>,
 *          Jan Romann <jan.romann@uni-bremen.de>
 * Date   : 05/09/2022
 * Copyright :  Jan Romann
 */

import 'dart:async';
import 'dart:typed_data';

import 'package:dtls2/dtls2.dart';
import 'package:typed_data/typed_buffers.dart';

import '../coap_message.dart';
import '../event/coap_event_bus.dart';
import 'coap_inetwork.dart';
import 'coap_network_udp.dart';
import 'credentials/psk_credentials.dart' as internal;

/// Maps an [internal.PskCredentialsCallback] to one provided by the `dtls2`
/// libary.
PskCredentialsCallback? _createOpenSslPskCallback(
  final internal.PskCredentialsCallback? coapPskCredentialsCallback,
) {
  if (coapPskCredentialsCallback == null) {
    return null;
  }

  return (final identityHint) {
    final pskCredentials = coapPskCredentialsCallback(identityHint);

    return PskCredentials(
      identity: pskCredentials.identity,
      preSharedKey: pskCredentials.preSharedKey,
    );
  };
}

/// DTLS network using OpenSSL
class CoapNetworkUDPOpenSSL extends CoapNetworkUDP {
  /// Initialize with an [address] and a [port].
  ///
  /// This [CoapINetwork] can be configured to be used [withTrustedRoots] and
  /// to [verify] certificate chains. You can also indicate a list of [ciphers],
  /// see the [OpenSSL documentation] for more information on this.
  ///
  /// When passing a [pskCredentialsCallback], this network is also capable of
  /// using DTLS in Pre-Shared Key mode.
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
    final internal.PskCredentialsCallback? pskCredentialsCallback,
    final OpenSsl? libSsl,
    final OpenSsl? libCrypto,
  })  : _ciphers = ciphers,
        _verify = verify,
        _withTrustedRoots = withTrustedRoots,
        _rootCertificates = rootCertificates,
        _libSsl = libSsl,
        _libCrypto = libCrypto,
        _openSslPskCallback = _createOpenSslPskCallback(pskCredentialsCallback);

  DtlsClient? _dtlsClient;

  DtlsConnection? _dtlsConnection;

  final List<Uint8List> _rootCertificates;

  final bool _verify;

  final String? _ciphers;

  final bool _withTrustedRoots;

  final PskCredentialsCallback? _openSslPskCallback;

  final OpenSsl? _libSsl;

  final OpenSsl? _libCrypto;

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

    final context = DtlsClientContext(
      verify: _verify,
      withTrustedRoots: _withTrustedRoots,
      rootCertificates: _rootCertificates,
      ciphers: _ciphers,
      pskCredentialsCallback: _openSslPskCallback,
    );

    await bind();

    // TODO(JKRhb): Maybe the hostname needs to be included here as well.
    _dtlsClient = DtlsClient(
      socket!,
      context,
      libSsl: _libSsl,
      libCrypto: _libCrypto,
    );
    try {
      _dtlsConnection = await _dtlsClient
          ?.connect(address, port)
          .timeout(CoapINetwork.initTimeout);
    } on TimeoutException {
      await close();
      rethrow;
    }

    _receive();

    isClosed = false;
  }

  @override
  Future<void> close() async {
    await _dtlsClient?.close();
    super.close();
  }

  void _receive() {
    _dtlsConnection?.listen(
      (final datagram) {
        final message =
            CoapMessage.fromUdpPayload(Uint8Buffer()..addAll(datagram.data));
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
