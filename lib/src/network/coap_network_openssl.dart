// ignore_for_file: avoid_types_on_closure_parameters

/*
 * Package : Coap
 * Author : Sorunome <mail@sorunome.de>,
 *          Jan Romann <jan.romann@uni-bremen.de>
 * Date   : 05/09/2022
 * Copyright :  Jan Romann
 */

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:dtls2/dtls2.dart';
import 'package:typed_data/typed_buffers.dart';

import '../coap_constants.dart';
import '../coap_message.dart';
import '../event/coap_event_bus.dart';
import 'cache.dart';
import 'coap_inetwork.dart';
import 'coap_network_udp.dart';
import 'credentials/psk_credentials.dart' as internal;

/// Maps an [internal.PskCredentialsCallback] to one provided by the `dtls2`
/// libary.
PskCredentialsCallback? _createOpenSslPskCallback(
  final internal.PskCredentialsCallback? coapPskCredentialsCallback,
  final Uri uri,
) {
  if (coapPskCredentialsCallback == null) {
    return null;
  }

  return (final identityHint) {
    final pskCredentials = coapPskCredentialsCallback(identityHint, uri);

    return PskCredentials(
      identity: pskCredentials.identity,
      preSharedKey: pskCredentials.preSharedKey,
    );
  };
}

/// DTLS network using OpenSSL
class CoapNetworkUDPOpenSSL extends CoapNetworkUDP {
  /// Initializes a new [CoapNetworkUDPOpenSSL].
  ///
  /// This [CoapINetwork] can be configured to be used [withTrustedRoots] and
  /// to [verify] certificate chains. You can also indicate a list of [ciphers],
  /// see the [OpenSSL documentation] for more information on this.
  ///
  /// When passing a [pskCredentialsCallback], this network is also capable of
  /// using DTLS in Pre-Shared Key mode.
  ///
  /// [OpenSSL documentation]: https://www.openssl.org/docs/man1.1.1/man1/ciphers.html
  CoapNetworkUDPOpenSSL({
    required final bool verify,
    required final bool withTrustedRoots,
    required final List<Uint8List> rootCertificates,
    super.namespace,
    final String? ciphers,
    final internal.PskCredentialsCallback? pskCredentialsCallback,
    final DynamicLibrary? libSsl,
    final DynamicLibrary? libCrypto,
  })  : _verify = verify,
        _withTrustedRoots = withTrustedRoots,
        _rootCertificates = rootCertificates,
        _ciphers = ciphers,
        _pskCredentialsCallback = pskCredentialsCallback,
        _libSsl = libSsl,
        _libCrypto = libCrypto;

  final bool _verify;

  final bool _withTrustedRoots;

  final List<Uint8List> _rootCertificates;

  final String? _ciphers;

  final internal.PskCredentialsCallback? _pskCredentialsCallback;

  DtlsClient? _dtls4Client;

  DtlsClient? _dtls6Client;

  Future<DtlsClient> _createClient(final InternetAddress bindAddress) =>
      DtlsClient.bind(bindAddress, 0, libSsl: _libSsl, libCrypto: _libCrypto);

  Future<DtlsClient> _checkExistingClient(
    final DtlsClient? existingClient,
    final InternetAddress bindAddress,
  ) async {
    final DtlsClient newClient;

    if (existingClient == null) {
      eventBus.fire(CoapSocketInitEvent());
      newClient = await _createClient(bindAddress);
    } else {
      return existingClient;
    }

    return newClient;
  }

  Future<DtlsClient> _obtainClient(final InternetAddress address) async {
    final internetAddressType = address.type;

    final DtlsClient client;
    if (internetAddressType == InternetAddressType.IPv4) {
      client =
          await _checkExistingClient(_dtls4Client, InternetAddress.anyIPv4);
      _dtls4Client = client;
    } else {
      client =
          await _checkExistingClient(_dtls6Client, InternetAddress.anyIPv6);
      _dtls6Client = client;
    }

    return client;
  }

  final DynamicLibrary? _libSsl;

  final DynamicLibrary? _libCrypto;

  final Map<int, DtlsConnection> connections = {};

  static int _connectionHashFunction(final Uri uri) {
    const emptyPort = 0;
    final uriPort = uri.port;

    final hashPort =
        uriPort != emptyPort ? uriPort : CoapConstants.defaultSecurePort;

    return Object.hash(uri.scheme, uri.host, hashPort);
  }

  final _connections = Cache<Uri, DtlsConnection>(_connectionHashFunction);

  DtlsClientContext _createContext(final Uri uri) => DtlsClientContext(
        verify: _verify,
        withTrustedRoots: _withTrustedRoots,
        rootCertificates: _rootCertificates,
        ciphers: _ciphers,
        pskCredentialsCallback:
            _createOpenSslPskCallback(_pskCredentialsCallback, uri),
      );

  Future<DtlsConnection> _obtainConnection(final Uri uri) async {
    final cachedConnection = _connections.retrieve(uri);

    if (cachedConnection != null && cachedConnection.connected) {
      return cachedConnection;
    }

    final address = await lookupHost(uri);
    final uriPort = uri.port;
    final port = uriPort != 0 ? uriPort : CoapConstants.defaultSecurePort;

    final client = await _obtainClient(address);
    final context = _createContext(uri);
    final newConnection = await client.connect(
      address,
      port,
      context,
      hostname: uri.host,
      timeout: CoapINetwork.initTimeout,
    );
    _connections.save(uri, newConnection);
    _receive(uri, newConnection);
    return newConnection;
  }

  @override
  Future<void> sendMessage(final CoapMessage coapRequest, final Uri uri) async {
    if (isClosed) {
      return;
    }

    final connection = await _obtainConnection(uri);
    final data = coapRequest.toUdpPayload();
    final bytes = Uint8List.view(data.buffer, data.offsetInBytes, data.length);
    connection.send(bytes);
    enableRetransmission(coapRequest);
  }

  @override
  Future<void> close() async {
    if (!isClosed) {
      await _dtls4Client?.close();
      _dtls4Client = null;
      await _dtls6Client?.close();
      _dtls6Client = null;
    }
    super.close();
  }

  void _receive(final Uri uri, final DtlsConnection connection) {
    connection.listen(
      (final datagram) {
        final message =
            CoapMessage.fromUdpPayload(Uint8Buffer()..addAll(datagram.data));
        eventBus.fire(
          CoapMessageReceivedEvent(
            message,
            datagram.address,
            datagram.port,
            scheme: 'coaps',
          ),
        );
      },
      onError: (final Object e, final StackTrace s) =>
          eventBus.fire(CoapSocketErrorEvent(e, s)),
      onDone: () {
        _connections.remove(uri);
      },
    );
  }
}
