/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// draft-ietf-core-coap-08
class CoapDraft08 implements CoapISpec {
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
  static const int maxOptionDelta = (1 << optionDeltaBits) - 1;

  /// Max Option length base
  static const int maxOptionLengthBase = (1 << optionLengthBaseBits) - 2;

  /// Fence post divisor position
  static const int fencepostDivisor = 14;

  CoapILogger _log = CoapLogManager().logger;

  @override
  String get name => 'draft-ietf-core-coap-08';

  @override
  int get defaultPort => 5683;

  @override
  CoapIMessageEncoder newMessageEncoder() => CoapMessageEncoder08();

  @override
  CoapIMessageDecoder newMessageDecoder(typed.Uint8Buffer data) =>
      CoapMessageDecoder08(data);

  @override
  typed.Uint8Buffer encode(CoapMessage msg) =>
      newMessageEncoder().encodeMessage(msg);

  @override
  CoapMessage decode(typed.Uint8Buffer bytes) =>
      newMessageDecoder(bytes).decodeMessage();

  /// Option number
  static int getOptionNumber(int optionType) {
    switch (optionType) {
      case optionTypeReserved:
        return 0;
      case optionTypeContentType:
        return 1;
      case optionTypeMaxAge:
        return 2;
      case optionTypeProxyUri:
        return 3;
      case optionTypeETag:
        return 4;
      case optionTypeUriHost:
        return 5;
      case optionTypeLocationPath:
        return 6;
      case optionTypeUriPort:
        return 7;
      case optionTypeLocationQuery:
        return 8;
      case optionTypeUriPath:
        return 9;
      case optionTypeToken:
        return 11;
      case optionTypeUriQuery:
        return 15;
      case optionTypeObserve:
        return 10;
      case optionTypeAccept:
        return 12;
      case optionTypeIfMatch:
        return 13;
      case optionTypeFencepostDivisor:
        return 14;
      case optionTypeBlock2:
        return 17;
      case optionTypeBlock1:
        return 19;
      case optionTypeIfNoneMatch:
        return 21;
      default:
        return optionType;
    }
  }

  /// Option type
  static int getOptionType(int optionNumber) {
    switch (optionNumber) {
      case 0:
        return optionTypeReserved;
      case 1:
        return optionTypeContentType;
      case 2:
        return optionTypeMaxAge;
      case 3:
        return optionTypeProxyUri;
      case 4:
        return optionTypeETag;
      case 5:
        return optionTypeUriHost;
      case 6:
        return optionTypeLocationPath;
      case 7:
        return optionTypeUriPort;
      case 8:
        return optionTypeLocationQuery;
      case 9:
        return optionTypeUriPath;
      case 11:
        return optionTypeToken;
      case 15:
        return optionTypeUriQuery;
      case 10:
        return optionTypeObserve;
      case 12:
        return optionTypeAccept;
      case 13:
        return optionTypeIfMatch;
      case 14:
        return optionTypeFencepostDivisor;
      case 17:
        return optionTypeBlock2;
      case 19:
        return optionTypeBlock1;
      case 21:
        return optionTypeIfNoneMatch;
      default:
        return optionNumber;
    }
  }

  /// Next fence post
  static int nextFencepost(int optionNumber) =>
      (optionNumber / fencepostDivisor + 1).toInt() * fencepostDivisor;

  /// Is a fence post
  static bool isFencepost(int type) => type % fencepostDivisor == 0;
}
