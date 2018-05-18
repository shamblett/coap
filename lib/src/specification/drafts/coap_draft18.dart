/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// draft-ietf-core-coap-18
class CoapDraft18 implements CoapISpec {
  static const int version = 1;
  static const int versionBits = 2;
  static const int typeBits = 2;
  static const int tokenLengthBits = 4;
  static const int codeBits = 8;
  static const int idBits = 16;
  static const int optionDeltaBits = 4;
  static const int optionLengthBits = 4;
  static const int payloadMarker = 0xFF;

  static CoapILogger _log = new CoapLogManager("console").logger;

  String get name => "draft-ietf-core-coap-18";

  int get defaultPort => 5683;

  CoapIMessageEncoder newMessageEncoder() {
    return new CoapMessageEncoder18();
  }

  CoapIMessageDecoder newMessageDecoder(typed.Uint8Buffer data) {
    return new CoapMessageDecoder18(data);
  }

  typed.Uint8Buffer encode(CoapMessage msg) {
    return newMessageEncoder().encodeMessage(msg);
  }

  CoapMessage decode(typed.Uint8Buffer bytes) {
    return newMessageDecoder(bytes).decodeMessage();
  }

  /// Calculates the value used in the extended option fields as specified
  /// in draft-ietf-core-coap-18, section 3.1.
  static int getValueFromOptionNibble(int nibble, CoapDatagramReader datagram) {
    if (nibble < 13) {
      return nibble;
    } else if (nibble == 13) {
      return datagram.read(8) + 13;
    } else if (nibble == 14) {
      return datagram.read(16) + 269;
    } else {
      _log.warn("Unsupported option delta $nibble");
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
      _log.warn("Unsupported option delta $optionValue");
      return 0;
    }
  }
}
