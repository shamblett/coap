/*
 * Package : Coap
 * Author : Jan Romann <jan.romann@uni-bremen.de>
 * Date   : 05/09/2022
 * Copyright :  Jan Romann
 */

import 'dart:typed_data';

/// Function signature for a callback function for retrieving/generating
/// [PskCredentials].
///
/// As the format of the [identityHint] is not well-defined, this parameter
/// can probably be ignored in most cases, when both the identity and the key
/// are known in advance.
typedef PskCredentialsCallback = PskCredentials Function(
  Uint8List identityHint,
  Uri uri,
);

/// Credentials used for PSK Cipher Suites consisting of an [identity]
/// and a [preSharedKey].
class PskCredentials {
  Uint8List identity;

  Uint8List preSharedKey;

  PskCredentials({required this.identity, required this.preSharedKey});
}
