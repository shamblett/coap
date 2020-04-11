/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Message decoder 012
class CoapMessageDecoder12 extends CoapMessageDecoder {
  /// Construction
  CoapMessageDecoder12(typed.Uint8Buffer data) : super(data) {
    readProtocol();
  }

  int _optionCount;

  @override
  bool get isWellFormed => _version == CoapDraft12.version;

  @override
  void readProtocol() {
    // Read headers
    _version = _reader.read(CoapDraft12.versionBits);
    _type = _reader.read(CoapDraft12.typeBits);
    _optionCount = _reader.read(CoapDraft12.optionCountBits);
    _code = _reader.read(CoapDraft12.codeBits);
    _id = _reader.read(CoapDraft12.idBits);
  }

  @override
  void parseMessage(CoapMessage message) {
    // Read options
    var currentOption = 0;
    var hasMoreOptions = _optionCount == 15;
    for (var i = 0;
        (i < _optionCount || hasMoreOptions) && _reader.bytesAvailable;
        i++) {
      // first 4 option bits: either option jump or option delta
      var optionDelta = _reader.read(CoapDraft12.optionDeltaBits);

      if (optionDelta == 15) {
        // option jump or end-of-options marker
        final bits = _reader.read(4);
        switch (bits) {
          case 0:
            // end-of-options marker read (0xF0), payload follows
            hasMoreOptions = false;
            continue;
          case 1:
            // 0xF1 (Delta = 15)
            optionDelta = 15 + _reader.read(CoapDraft12.optionDeltaBits);
            break;
          case 2:
            // Delta = ((Option Jump Value) + 2) * 8
            optionDelta = (_reader.read(8) + 2) * 8 +
                _reader.read(CoapDraft12.optionDeltaBits);
            break;
          case 3:
            // Delta = ((Option Jump Value) + 258) * 8
            optionDelta = (_reader.read(16) + 258) * 8 +
                _reader.read(CoapDraft12.optionDeltaBits);
            break;
          default:
            break;
        }
      }

      currentOption += optionDelta;
      final currentOptionType = CoapDraft12.getOptionType(currentOption);

      var length = _reader.read(CoapDraft12.optionLengthBaseBits);
      if (length == 15) {
        // When the Length field is set to 15, another byte is added as
        // an 8-bit unsigned integer whose value is added to the 15,
        // allowing option value lengths of 15-270 bytes. For option
        // lengths beyond 270 bytes, we reserve the value 255 of an
        // extension byte to mean
        // "add 255, read another extension byte".
        var additionalLength = 0;
        do {
          additionalLength = _reader.read(8);
          length += additionalLength;
        } while (additionalLength >= 255);
      }

      // read option
      final opt = CoapOption.create(currentOptionType);
      opt.valueBytes = _reader.readBytes(length);

      message.addOption(opt);
    }

    message.token ??= CoapConstants.emptyToken;

    message.payload = _reader.readBytesLeft();
  }
}
