/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

/// RFC 7252
class CoapRfc7252 {
  static const int version = 1;

  /// Version bit length
  static const int versionBits = 2;

  /// Type bit length
  static const int typeBits = 2;

  /// Token bit length
  static const int tokenLengthBits = 4;

  /// Code bit length
  static const int codeBits = 8;

  /// Id bit length
  static const int idBits = 16;

  /// Option delta bit length
  static const int optionDeltaBits = 4;

  /// Option length bit length
  static const int optionLengthBits = 4;

  /// Payload marker
  static const int payloadMarker = 0xFF;
}
