/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Message decoder 013
class CoapMessageDecoder13 extends CoapMessageDecoder {
  /// Construction
  CoapMessageDecoder13(typed.Uint8Buffer data) : super(data) {
    readProtocol();
  }

  @override
  bool get isWellFormed => _version == CoapDraft13.version;

  @override
  void readProtocol() {
    // Read headers
    _version = _reader.read(CoapDraft13.versionBits);
    _type = _reader.read(CoapDraft13.typeBits);
    _tokenLength = _reader.read(CoapDraft13.tokenLengthBits);
    _code = _reader.read(CoapDraft13.codeBits);
    _id = _reader.read(CoapDraft13.idBits);
  }

  @override
  void parseMessage(CoapMessage message) {
    // Read token
    if (_tokenLength > 0) {
      message.token = _reader.readBytes(_tokenLength);
    } else {
      message.token = CoapConstants.emptyToken;
    }

    // Read options
    var currentOption = 0;
    while (_reader.bytesAvailable) {
      final nextByte = _reader.readNextByte();
      if (nextByte == CoapDraft13.payloadMarker) {
        if (!_reader.bytesAvailable) {
          // The presence of a marker followed by a zero-length payload
          // must be processed as a message format error
          throw StateError('Decoder13 - Marker followed by 0 length payload');
        }

        message.payload = _reader.readBytesLeft();
      } else {
        // The first 4 bits of the byte represent the option delta
        final optionDeltaNibble = (0xF0 & nextByte) >> 4;
        currentOption +=
            CoapDraft13.getValueFromOptionNibble(optionDeltaNibble, _reader);

        // The second 4 bits represent the option length
        final optionLengthNibble = 0x0F & nextByte;
        final optionLength =
            CoapDraft13.getValueFromOptionNibble(optionLengthNibble, _reader);

        // Read option
        final currentOptionType = CoapDraft13.getOptionType(currentOption);
        final opt = CoapOption.create(currentOptionType);
        opt.valueBytes = _reader.readBytes(optionLength);
        message.addOption(opt);
      }
    }
  }
}
