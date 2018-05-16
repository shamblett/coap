/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// draft-ietf-core-coap-12
class CoapDraft12 implements CoapISpec {
  static const int version = 1;
  static const int versionBits = 2;
  static const int typeBits = 2;
  static const int optionCountBits = 4;
  static const int codeBits = 8;
  static const int idBits = 16;
  static const int optionDeltaBits = 4;
  static const int optionLengthBaseBits = 4;
  static const int optionLengthExtendedBits = 8;
  static const int maxOptionDelta = 14;
  static const int singleOptionJumpBits = 8;
  static const int maxOptionLengthBase = (1 << optionLengthBaseBits) - 2;

  static CoapILogger _log = new CoapLogManager("console").logger;

  String get name => "draft-ietf-core-coap-12";

  int get defaultPort => 5683;

  CoapIMessageEncoder newMessageEncoder() {
    return new CoapMessageEncoder12();
  }

  CoapIMessageDecoder newMessageDecoder(typed.Uint8Buffer data) {
    return new CoapMessageDecoder12(data);
  }

  typed.Uint8Buffer encode(CoapMessage msg) {
    return newMessageEncoder().encodeMessage(msg);
  }

  CoapMessage decode(typed.Uint8Buffer bytes) {
    return newMessageDecoder(bytes).decodeMessage();
  }

  static int getOptionNumber(int optionType) {
    if (optionType == optionTypeAccept) {
      return 16;
    } else {
      return optionType;
    }
  }

  static int getOptionType(int optionNumber) {
    if (optionNumber == 16) {
      return optionTypeAccept;
    } else {
      return optionNumber;
    }
  }
}
