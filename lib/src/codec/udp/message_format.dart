/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

/// The defined versions for CoAP using UDP.
///
/// At the moment (and probably for the foreseeable future) only version 1 has
/// been defined.
enum Version {
  /// The current CoAP version number
  version1(1);

  const Version(this.numericValue);

  /// The numeric value (e.g., `1`) of this [Version].
  final int numericValue;

  static Version? decode(final int number) {
    if (number != version1.numericValue) {
      return null;
    }

    return version1;
  }

  /// Version bit length
  static const int bitLength = 2;
}

/// Token bit length
const int tokenLengthBits = 4;

/// Id bit length
const int idBits = 16;

/// Option delta bit length
const int optionDeltaBits = 4;

/// Option length bit length
const int optionLengthBits = 4;

/// Payload marker
const int payloadMarker = 0xFF;
