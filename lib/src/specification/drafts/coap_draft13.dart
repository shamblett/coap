/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// draft-ietf-core-coap-13
class CoapDraft13 implements CoapISpec {
  /// Version
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

  /// Option length bits
  static const int optionLengthBits = 4;

  /// Payload marker
  static const int payloadMarker = 0xFF;

  static final CoapILogger _log = CoapLogManager().logger;

  @override
  String get name => 'draft-ietf-core-coap-13';

  @override
  int get defaultPort => 5683;

  @override
  CoapIMessageEncoder newMessageEncoder() => CoapMessageEncoder13();

  @override
  CoapIMessageDecoder newMessageDecoder(typed.Uint8Buffer data) =>
      CoapMessageDecoder13(data);

  @override
  typed.Uint8Buffer encode(CoapMessage msg) =>
      newMessageEncoder().encodeMessage(msg);

  @override
  CoapMessage decode(typed.Uint8Buffer bytes) =>
      newMessageDecoder(bytes).decodeMessage();

  /// Calculates the value used in the extended option fields as specified
  /// in draft-ietf-core-coap-13, section 3.1.
  static int getValueFromOptionNibble(int nibble, CoapDatagramReader datagram) {
    if (nibble < 13) {
      return nibble;
    } else if (nibble == 13) {
      return datagram.read(8) + 13;
    } else if (nibble == 14) {
      return datagram.read(16) + 269;
    } else {
      _log.warn('15 is reserved for payload marker, message format error');
      return 0;
    }
  }

  /// Returns the 4-bit option header value.
  static int getOptionNibble(int optionValue) {
    if (optionValue <= 12) {
      return optionValue;
    } else if (optionValue <= 255 + 13) {
      return 13;
    } else if (optionValue <= 65535 + 269) {
      return 14;
    } else {
      _log.warn('The option value $optionValue is too large to be '
          'encoded; Max allowed is 65804.');
      return 0;
    }
  }

  /// Option number
  static int getOptionNumber(int optionType) {
    if (optionType == optionTypeAccept) {
      return 16;
    } else {
      return optionType;
    }
  }

  /// Option type
  static int getOptionType(int optionNumber) {
    if (optionNumber == 16) {
      return optionTypeAccept;
    } else {
      return optionNumber;
    }
  }
}
