/*
 * Package : Coap
 * Author : Jan Romann <jan.romann@uni-bremen.de>
 * Date   : 04/01/2022
 * Copyright :  Jan Romann
 */

import 'package:dart_tinydtls/dart_tinydtls.dart';
import 'package:typed_data/typed_data.dart';

import '../event/coap_event_bus.dart';
import '../net/coap_internet_address.dart';
import 'coap_inetwork.dart';
import 'credentials/ecdsa_keys.dart' as internal;
import 'credentials/psk_credentials.dart' as internal;

/// Maps an [internal.PskCredentialsCallback] to one provided by the tinydtls
/// libary.
PskCallback? _createTinyDtlsPskCallback(
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

/// Maps an [internal.EcdsaCurve] to one provided by the tinydtls
/// libary.
EcdsaCurve _mapEcdsaCurve(final internal.EcdsaCurve ecdsaCurve) {
  switch (ecdsaCurve) {
    case internal.EcdsaCurve.secp256r1:
      return EcdsaCurve.secp256r1;
  }
}

EcdsaKeys? _createTinyDtlsEcdsaKeys(final internal.EcdsaKeys? coapEcdsaKeys) {
  if (coapEcdsaKeys == null) {
    return null;
  }

  final ecdsaCurve = _mapEcdsaCurve(coapEcdsaKeys.ecdsaCurve);

  return EcdsaKeys(
    ecdsaCurve,
    privateKey: coapEcdsaKeys.privateKey,
    publicKeyX: coapEcdsaKeys.publicKeyX,
    publicKeyY: coapEcdsaKeys.publicKeyY,
  );
}

/// DTLS network using dart_tinydtls
class CoapNetworkTinyDtls implements CoapINetwork {
  /// Initialize with an [address] and a [port] as well as credentials.
  ///
  /// These credentials can either be provided by a [pskCredentialsCallback]
  /// that returns [PskCredentials] (a combination of an identity and a
  /// pre-shared key) and/or consist of [ecdsaKeys] (an public/private key pair
  /// for using DTLS in Raw Public Key mode, applying Ellipctic Curve
  /// Cryptography).
  ///
  /// An optional [_tinyDtlsInstance] object can be passed in case
  /// [TinyDTLS] should not be available at the default locations.
  CoapNetworkTinyDtls(
    this.address,
    this.port,
    this._tinyDtlsInstance, {
    final String namespace = '',
    final internal.PskCredentialsCallback? pskCredentialsCallback,
    final internal.EcdsaKeys? ecdsaKeys,
  })  : _tinydtlsPskCallback =
            _createTinyDtlsPskCallback(pskCredentialsCallback),
        _ecdsaKeys = _createTinyDtlsEcdsaKeys(ecdsaKeys),
        _eventBus = CoapEventBus(namespace: namespace);

  final CoapEventBus _eventBus;

  final PskCallback? _tinydtlsPskCallback;

  final EcdsaKeys? _ecdsaKeys;

  final TinyDTLS? _tinyDtlsInstance;

  @override
  final CoapInternetAddress address;

  @override
  final int port;

  @override
  String get namespace => _eventBus.namespace;

  bool _bound = false;

  DtlsClient? _dtlsClient;

  DtlsConnection? _connection;

  void _checkConnectionStatus() {
    if (_connection?.connected != true) {
      _bound = false;
      _connection?.close();
      throw CoapDtlsException('Not connected to DTLS peer!');
    }
  }

  @override
  Future<int> send(
    final Uint8Buffer data, [
    final CoapInternetAddress? address,
  ]) async {
    if (_connection?.connected != true) {
      _bound = false;
      await bind();
    }

    _checkConnectionStatus();

    return _connection!.send(data.toList());
  }

  @override
  void receive() {
    _connection?.listen((final datagram) {
      final buff = Uint8Buffer();
      if (datagram.data.isNotEmpty) {
        buff.addAll(datagram.data.toList());
        final coapAddress =
            CoapInternetAddress(datagram.address.type, datagram.address);
        final rxEvent = CoapDataReceivedEvent(buff, coapAddress);
        _eventBus.fire(rxEvent);
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
    final bindAddress = address.bind;
    _dtlsClient ??=
        await DtlsClient.bind(bindAddress, 0, tinyDtls: _tinyDtlsInstance);
    _connection = await _dtlsClient!.connect(
      address.address,
      port,
      pskCallback: _tinydtlsPskCallback,
      ecdsaKeys: _ecdsaKeys,
    );
    _checkConnectionStatus();
    receive();
    _bound = true;
  }

  @override
  void close() {
    _dtlsClient?.close();
  }
}
