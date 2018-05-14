/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// draft-ietf-core-coap-03
class CoapDraft03 implements CoapISpec {
  static const int version = 1;
  static const int versionBits = 2;
  static const int typeBits = 2;
  static const int optionCountBits = 4;
  static const int codeBits = 8;
  static const int idBits = 16;
  static const int optionDeltaBits = 4;
  static const int optionLengthBaseBits = 4;
  static const int optionLengthExtendedBits = 8;
  static const int maxOptionDelta = (1 << optionDeltaBits) - 1;
  static const int maxOptionLengthBase = (1 << optionLengthBaseBits) - 2;
  static const int fencepostDivisor = 14;

  static CoapILogger _log = new CoapLogManager("console").logger;

  String get name => "draft-ietf-core-coap-03";

  int get defaultPort => 61616;

  CoapIMessageEncoder newMessageEncoder() {
    return new messageEncoder03();
  }
}
