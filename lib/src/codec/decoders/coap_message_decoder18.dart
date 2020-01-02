/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

// ignore_for_file: omit_local_variable_types
// ignore_for_file: unnecessary_final
// ignore_for_file: cascade_invocations
// ignore_for_file: avoid_print
// ignore_for_file: avoid_types_on_closure_parameters
// ignore_for_file: avoid_returning_this
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes
// ignore_for_file: prefer_null_aware_operators
// ignore_for_file: avoid_annotating_with_dynamic

/// Message decoder 18
class CoapMessageDecoder18 extends CoapMessageDecoder {
  /// Construction
  CoapMessageDecoder18(typed.Uint8Buffer data) : super(data) {
    readProtocol();
  }

  @override
  bool get isWellFormed => _version == CoapDraft18.version;

  @override
  void readProtocol() {
    // Read headers
    _version = _reader.read(CoapDraft18.versionBits);
    _type = _reader.read(CoapDraft18.typeBits);
    _tokenLength = _reader.read(CoapDraft18.tokenLengthBits);
    _code = _reader.read(CoapDraft18.codeBits);
    _id = _reader.read(CoapDraft18.idBits);
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
    int currentOption = 0;
    while (_reader.bytesAvailable) {
      final int nextByte = _reader.readNextByte();
      if (nextByte == CoapDraft18.payloadMarker) {
        if (!_reader.bytesAvailable) {
          // The presence of a marker followed by a zero-length payload
          // must be processed as a message format error
          throw StateError('Decoder18 - Marker followed by 0 length payload');
        }

        message.payload = _reader.readBytesLeft();
      } else {
        // The first 4 bits of the byte represent the option delta
        final int optionDeltaNibble = (0xF0 & nextByte) >> 4;
        currentOption +=
            CoapDraft18.getValueFromOptionNibble(optionDeltaNibble, _reader);

        // The second 4 bits represent the option length
        final int optionLengthNibble = 0x0F & nextByte;
        final int optionLength =
            CoapDraft18.getValueFromOptionNibble(optionLengthNibble, _reader);

        // Read option
        final CoapOption opt = CoapOption.create(currentOption);
        opt.valueBytes = _reader.readBytes(optionLength);
        message.addOption(opt);
      }
    }
  }
}
