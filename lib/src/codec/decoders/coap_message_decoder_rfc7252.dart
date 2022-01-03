/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Message decoder 18
class CoapMessageDecoder18 extends CoapMessageDecoder {
  /// Construction
  CoapMessageDecoder18(typed.Uint8Buffer data) : super(data) {
    readProtocol();
  }

  @override
  bool get isWellFormed => _version == CoapRfc7252.version;

  @override
  void readProtocol() {
    // Read headers
    _version = _reader!.read(CoapRfc7252.versionBits);
    _type = _reader!.read(CoapRfc7252.typeBits);
    _tokenLength = _reader!.read(CoapRfc7252.tokenLengthBits);
    _code = _reader!.read(CoapRfc7252.codeBits);
    _id = _reader!.read(CoapRfc7252.idBits);
  }

  @override
  void parseMessage(CoapMessage message) {
    // Read token
    if (_tokenLength > 0) {
      message.token = _reader!.readBytes(_tokenLength);
    } else {
      message.token = CoapConstants.emptyToken;
    }
    // Read options
    var currentOption = 0;
    while (_reader!.bytesAvailable) {
      final nextByte = _reader!.readNextByte();
      if (nextByte == CoapRfc7252.payloadMarker) {
        if (!_reader!.bytesAvailable) {
          // The presence of a marker followed by a zero-length payload
          // must be processed as a message format error
          throw StateError('Decoder18 - Marker followed by 0 length payload');
        }

        message.payload = _reader!.readBytesLeft();
      } else {
        // The first 4 bits of the byte represent the option delta
        final optionDeltaNibble = (0xF0 & nextByte) >> 4;
        currentOption +=
            CoapRfc7252.getValueFromOptionNibble(optionDeltaNibble, _reader);

        // The second 4 bits represent the option length
        final optionLengthNibble = 0x0F & nextByte;
        final optionLength =
            CoapRfc7252.getValueFromOptionNibble(optionLengthNibble, _reader);

        // Read option
        final opt = CoapOption.create(currentOption);
        opt.valueBytes = _reader!.readBytes(optionLength);
        // Reverse byte order for numeric options
        if (CoapOption.getFormatByType(opt.type) == optionFormat.integer) {
          final valueBytes = opt.valueBytes;
          if (valueBytes != null) {
            final reversedBytes = valueBytes.reversed;
            opt.valueBytes = typed.Uint8Buffer()..addAll(reversedBytes);
          }
        }

        message.addOption(opt);
      }
    }
  }
}
