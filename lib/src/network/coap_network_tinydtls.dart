/*
 * Package : Coap
 * Author : Jan Romann <jan.romann@uni-bremen.de>
 * Date   : 04/01/2022
 * Copyright :  Jan Romann
 */

import 'dart:async';
import 'dart:io';

import 'package:dart_tinydtls/dart_tinydtls.dart';
import 'package:typed_data/typed_data.dart';

import '../event/coap_event_bus.dart';
import 'coap_inetwork.dart';
import 'coap_network_udp.dart';
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
class CoapNetworkUDPTinyDtls extends CoapNetworkUDP {
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
  CoapNetworkUDPTinyDtls(
    super.address,
    super.port,
    super.bindAddress,
    this._tinyDtlsInstance, {
    final super.namespace,
    final internal.PskCredentialsCallback? pskCredentialsCallback,
    final internal.EcdsaKeys? ecdsaKeys,
  })  : _tinydtlsPskCallback =
            _createTinyDtlsPskCallback(pskCredentialsCallback),
        _ecdsaKeys = _createTinyDtlsEcdsaKeys(ecdsaKeys);

  final PskCallback? _tinydtlsPskCallback;

  final EcdsaKeys? _ecdsaKeys;

  final TinyDTLS? _tinyDtlsInstance;

  DtlsClient? _dtlsClient;

  DtlsConnection? _connection;

  @override
  void send(
    final Uint8Buffer data, [
    final InternetAddress? address,
  ]) {
    if (isClosed) {
      return;
    }

    _connection!.send(data);
  }

  @override
  Future<void> init() async {
    if (!isClosed || !shouldReinitialize) {
      return;
    }

    await bind();

    _dtlsClient = DtlsClient(
      socket!,
      tinyDTLS: _tinyDtlsInstance,
      maxTimeoutSeconds: CoapINetwork.initTimeout.inSeconds,
    );
    _connection = await _dtlsClient!.connect(
      address,
      port,
      pskCallback: _tinydtlsPskCallback,
      ecdsaKeys: _ecdsaKeys,
    );

    _connection?.listen(
      (final d) => eventBus.fire(CoapDataReceivedEvent(d.data, address)),
      // ignore: avoid_types_on_closure_parameters
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

    isClosed = false;
  }

  @override
  void close() {
    _dtlsClient?.close();
    super.close();
  }
}
