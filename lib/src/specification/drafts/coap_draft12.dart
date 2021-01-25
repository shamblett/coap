/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// draft-ietf-core-coap-12
class CoapDraft12 implements CoapISpec {
  /// Version
  static const int version = 1;

  /// Version bit length
  static const int versionBits = 2;

  /// Type bit length
  static const int typeBits = 2;

  /// Option count nit length
  static const int optionCountBits = 4;

  /// Code bit length
  static const int codeBits = 8;

  /// Id bit length
  static const int idBits = 16;

  /// Option delta bit length
  static const int optionDeltaBits = 4;

  /// Option length base bit length
  static const int optionLengthBaseBits = 4;

  /// Option length extended bit length
  static const int optionLengthExtendedBits = 8;

  /// Max option delta
  static const int maxOptionDelta = 14;

  /// Single option jump bits
  static const int singleOptionJumpBits = 8;

  /// Max Option length base
  static const int maxOptionLengthBase = (1 << optionLengthBaseBits) - 2;

  /// Fence post divisor position
  static const int fencepostDivisor = 14;

  @override
  String get name => 'draft-ietf-core-coap-12';

  @override
  int get defaultPort => 5683;

  @override
  CoapIMessageEncoder newMessageEncoder() => CoapMessageEncoder12();

  @override
  CoapIMessageDecoder newMessageDecoder(typed.Uint8Buffer data) =>
      CoapMessageDecoder12(data);

  @override
  typed.Uint8Buffer? encode(CoapMessage msg) =>
      newMessageEncoder().encodeMessage(msg);

  @override
  CoapMessage? decode(typed.Uint8Buffer bytes) =>
      newMessageDecoder(bytes).decodeMessage();

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
