/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Message decoder 03
class CoapMessageDecoder03 extends CoapMessageDecoder {
  /// Construction
  CoapMessageDecoder03(typed.Uint8Buffer data) : super(data) {
    readProtocol();
  }

  int _optionCount;

  @override
  bool get isWellFormed => _version == CoapDraft03.version;

  @override
  void readProtocol() {
    // Read headers
    _version = _reader.read(CoapDraft03.versionBits);
    _type = _reader.read(CoapDraft03.typeBits);
    _optionCount = _reader.read(CoapDraft03.optionCountBits);
    _code = CoapDraft03.mapInCode(_reader.read(CoapDraft03.codeBits));
    _id = _reader.read(CoapDraft03.idBits);
  }

  @override
  void parseMessage(CoapMessage message) {
    // Read options
    var currentOption = 0;
    for (var i = 0; i < _optionCount; i++) {
      // Read option delta bits
      final optionDelta = _reader.read(CoapDraft03.optionDeltaBits);

      currentOption += optionDelta;
      final currentOptionType = CoapDraft03.getOptionType(currentOption);

      if (CoapDraft03.isFencepost(currentOption)) {
        // Read number of options
        _reader.read(CoapDraft03.optionLengthBaseBits);
      } else {
        // Read option length
        var length = _reader.read(CoapDraft03.optionLengthBaseBits);
        if (length > CoapDraft03.maxOptionLengthBase) {
          // Read extended option length
          length += _reader.read(CoapDraft03.optionLengthExtendedBits);
        }
        // Read option
        var opt = CoapOption.create(currentOptionType);
        opt.valueBytes = _reader.readBytes(length);

        if (opt.type == optionTypeContentType) {
          final ct = opt.intValue;
          final ct2 = CoapDraft03.mapInMediaType(ct);
          if (ct != ct2) {
            opt = CoapOption.createVal(currentOptionType, ct2);
          }
        }

        message.addOption(opt);
      }
    }

    message.token ??= CoapConstants.emptyToken;

    message.payload = _reader.readBytesLeft();
  }
}
