/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Message decoder -8
class CoapMessageDecoder08 extends CoapMessageDecoder {
  /// Construction
  CoapMessageDecoder08(typed.Uint8Buffer data) : super(data) {
    readProtocol();
  }

  int _optionCount;

  @override
  bool get isWellFormed => _version == CoapDraft08.version;

  @override
  void readProtocol() {
    // Read headers
    _version = _reader.read(CoapDraft08.versionBits);
    _type = _reader.read(CoapDraft08.typeBits);
    _optionCount = _reader.read(CoapDraft08.optionCountBits);
    _code = _reader.read(CoapDraft08.codeBits);
    _id = _reader.read(CoapDraft08.idBits);
  }

  @override
  void parseMessage(CoapMessage message) {
    // Read options
    var currentOption = 0;
    for (var i = 0; i < _optionCount; i++) {
      // Read option delta bits
      final optionDelta = _reader.read(CoapDraft08.optionDeltaBits);

      currentOption += optionDelta;
      final currentOptionType = CoapDraft08.getOptionType(currentOption);

      if (CoapDraft08.isFencepost(currentOption)) {
        // Read number of options
        _reader.read(CoapDraft08.optionLengthBaseBits);
      } else {
        // Read option length
        var length = _reader.read(CoapDraft08.optionLengthBaseBits);
        if (length > CoapDraft08.maxOptionLengthBase) {
          // Read extended option length
          length += _reader.read(CoapDraft08.optionLengthExtendedBits);
        }
        // Read option
        final opt = CoapOption.create(currentOptionType);
        opt.valueBytes = _reader.readBytes(length);

        message.addOption(opt);
      }
    }

    message.token ??= CoapConstants.emptyToken;

    message.payload = _reader.readBytesLeft();
  }
}
