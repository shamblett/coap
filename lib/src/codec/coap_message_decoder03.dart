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
      int optionDelta = _reader.read(CoapDraft03.optionDeltaBits);

      currentOption += optionDelta;
      int currentOptionType = CoapDraft03.getOptionType(currentOption);

      if (CoapDraft03.isFencepost(currentOption)) {
        // read number of options
        m_reader.Read(OptionLengthBaseBits);
      }
      else {
        // read option length
        Int32 length = m_reader.Read(OptionLengthBaseBits);
        if (length > MaxOptionLengthBase) {
          // read extended option length
          length += m_reader.Read(OptionLengthExtendedBits);
        }
        // read option
        Option opt = Option.Create(currentOptionType);
        opt.RawValue = m_reader.ReadBytes(length);

        if (opt.Type == OptionType.ContentType) {
          Int32 ct = opt.IntValue;
          Int32 ct2 = MapInMediaType(ct);
          if (ct != ct2)
            opt = Option.Create(currentOptionType, ct2);
        }

        msg.AddOption(opt);
      }
    }

    if (msg.Token == null)
      msg.Token = CoapConstants.EmptyToken;

    msg.Payload = m_reader.ReadBytesLeft();
  }
}

}
