/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

import 'package:typed_data/typed_data.dart';

import '../../coap_constants.dart';
import '../../coap_message.dart';
import '../../coap_option.dart';
import '../../coap_option_type.dart';
import '../../specification/rfcs/coap_rfc7252.dart';
import 'coap_message_decoder.dart';

/// Message decoder 18
class CoapMessageDecoder18 extends CoapMessageDecoder {
  /// Construction
  CoapMessageDecoder18(super.data) {
    readProtocol();
  }

  @override
  bool get isWellFormed => version == CoapRfc7252.version;

  int? _version;

  @override
  int? get version => _version;

  int _tokenLength = 0;

  int? _id;

  @override
  int? get id => _id;

  @override
  void readProtocol() {
    // Read headers
    _version = super.reader.read(CoapRfc7252.versionBits);
    _type = super.reader.read(CoapRfc7252.typeBits);
    _tokenLength = super.reader.read(CoapRfc7252.tokenLengthBits);
    _code = super.reader.read(CoapRfc7252.codeBits);
    _id = super.reader.read(CoapRfc7252.idBits);
  }

  int? _type;

  @override
  int? get type => _type;

  int? _code;

  @override
  int? get code => _code;

  @override
  void parseMessage(final CoapMessage message) {
    // Read token
    if (_tokenLength > 0) {
      message.token = super.reader.readBytes(_tokenLength);
    } else {
      message.token = CoapConstants.emptyToken;
    }
    // Read options
    var currentOption = 0;
    while (super.reader.bytesAvailable) {
      final nextByte = super.reader.readNextByte();
      if (nextByte == CoapRfc7252.payloadMarker) {
        if (!super.reader.bytesAvailable) {
          // The presence of a marker followed by a zero-length payload
          // must be processed as a message format error
          throw StateError('Decoder18 - Marker followed by 0 length payload');
        }

        message.payload = super.reader.readBytesLeft();
      } else {
        // The first 4 bits of the byte represent the option delta
        final optionDeltaNibble = (0xF0 & nextByte) >> 4;
        currentOption += CoapRfc7252.getValueFromOptionNibble(
          optionDeltaNibble,
          super.reader,
        );

        // The second 4 bits represent the option length
        final optionLengthNibble = 0x0F & nextByte;
        final optionLength = CoapRfc7252.getValueFromOptionNibble(
          optionLengthNibble,
          super.reader,
        );

        // Read option
        final CoapOption opt;
        try {
          final optionType = OptionType.fromTypeNumber(currentOption);
          opt = CoapOption.create(optionType);
        } on UnknownElectiveOptionException {
          // Unknown elective options must be silently ignored
          continue;
        } on UnknownCriticalOptionException {
          // Messages with unknown critical options must be rejected
          message.hasUnknownCriticalOption = true;
          return;
        }
        opt.byteValue = super.reader.readBytes(optionLength);
        // Reverse byte order for numeric options
        if (opt.type.optionFormat == OptionFormat.integer) {
          opt.byteValue = Uint8Buffer()..addAll(opt.byteValue.reversed);
        }

        message.addOption(opt);
      }
    }
  }
}
