/*
 * Package : Coap
 * Author : Jan Romann <jan.romann@uni-bremen.de>
 * Date   : 05/09/2022
 * Copyright :  Jan Romann
 */

import 'dart:typed_data';

/// Enumeration of the supported elliptic curves.
enum EcdsaCurve {
  /// Represents the secp256r1 curve.
  secp256r1
}

extension _KeyLengthExtension on EcdsaCurve {
  int get keyLength {
    switch (this) {
      case EcdsaCurve.secp256r1:
        return 32;
    }
  }
}

enum _ArgumentType {
  x,
  y,
  private,
}

class _EcdsaValidationError extends ArgumentError {
  final EcdsaCurve _ecdsaCurve;

  final _ArgumentType _argumentType;

  final int _expectedByteLength;

  final int _actualByteLength;

  _EcdsaValidationError(
    this._ecdsaCurve,
    this._argumentType,
    this._expectedByteLength,
    this._actualByteLength,
  );

  String get _parameterDescription {
    if (_argumentType == _ArgumentType.private) {
      return 'private key';
    }

    return '${_argumentType.name} coordinate of the public key';
  }

  @override
  String get message {
    final expectedBitLength = _expectedByteLength * 8;

    return 'Expected a length of $_expectedByteLength bytes '
        '($expectedBitLength bits) for the $_parameterDescription of '
        'the curve ${_ecdsaCurve.name}, but found $_actualByteLength bytes '
        'instead!';
  }
}

class _Secp256r1ValidationError extends _EcdsaValidationError {
  _Secp256r1ValidationError(
    final _ArgumentType argumentType,
    final int actualByteLength,
  ) : super(
          EcdsaCurve.secp256r1,
          argumentType,
          EcdsaCurve.secp256r1.keyLength,
          actualByteLength,
        );
}

/// Class representing ECC keys (one private key and the x and y coordinates of
/// a public one).
///
/// Currently, only the mandatory Cipher Suite
/// `TLS_ECDHE_ECDSA_WITH_AES_128_CCM_8` is supported via tinydtls.
class EcdsaKeys {
  /// The elliptic curve these keys are associated with.
  final EcdsaCurve ecdsaCurve;

  /// The private key.
  final Uint8List privateKey;

  /// The x coordinate of the public key.
  final Uint8List publicKeyX;

  /// The y coordinate of the public key.
  final Uint8List publicKeyY;

  void _verifySecp256R1() {
    final keyLength = EcdsaCurve.secp256r1.keyLength;

    if (publicKeyX.length != keyLength) {
      throw _Secp256r1ValidationError(_ArgumentType.x, publicKeyX.length);
    }

    if (publicKeyY.length != keyLength) {
      throw _Secp256r1ValidationError(_ArgumentType.y, publicKeyY.length);
    }

    if (privateKey.length != keyLength) {
      throw _Secp256r1ValidationError(_ArgumentType.private, privateKey.length);
    }
  }

  void _verifyEcdsaKeys() {
    switch (ecdsaCurve) {
      case EcdsaCurve.secp256r1:
        _verifySecp256R1();
    }
  }

  /// Constructor.
  EcdsaKeys(
    this.ecdsaCurve, {
    required this.privateKey,
    required this.publicKeyX,
    required this.publicKeyY,
  }) {
    _verifyEcdsaKeys();
  }
}
