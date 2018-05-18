/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

class CoapMessageDecoder03 extends CoapMessageDecoder {
  CoapMessageDecoder03(typed.Uint8Buffer data) : super(data) {
    readProtocol();
  }

  int _optionCount;

  bool get isWellFormed => _version == CoapDraft03.version;

  void readProtocol() {
    // Read headers
    _version = _reader.read(CoapDraft03.versionBits);
    _type = _reader.read(CoapDraft03.typeBits);
    _optionCount = _reader.read(CoapDraft03.optionCountBits);
    _code = CoapDraft03.mapInCode(_reader.read(CoapDraft03.codeBits));
    _id = _reader.read(CoapDraft03.idBits);
  }

  void parseMessage(CoapMessage msg) {
    // Read options
    int currentOption = 0;
    for (int i = 0; i < _optionCount; i++) {
      // Read option delta bits
      final int optionDelta = _reader.read(CoapDraft03.optionDeltaBits);

      currentOption += optionDelta;
      final int currentOptionType = CoapDraft03.getOptionType(currentOption);

      if (CoapDraft03.isFencepost(currentOption)) {
        // Read number of options
        _reader.read(CoapDraft03.optionLengthBaseBits);
      } else {
        // Read option length
        int length = _reader.read(CoapDraft03.optionLengthBaseBits);
        if (length > CoapDraft03.maxOptionLengthBase) {
          // Read extended option length
          length += _reader.read(CoapDraft03.optionLengthExtendedBits);
        }
        // Read option
        CoapOption opt = CoapOption.create(currentOptionType);
        opt.valueBytes = _reader.readBytes(length);

        if (opt.type == optionTypeContentType) {
          final int ct = opt.intValue;
          final int ct2 = CoapDraft03.mapInMediaType(ct);
          if (ct != ct2) opt = CoapOption.createVal(currentOptionType, ct2);
        }

        msg.addOption(opt);
      }
    }

    if (msg.token == null) msg.token = CoapConstants.emptyToken;

    msg.payload = _reader.readBytesLeft();
  }
}
