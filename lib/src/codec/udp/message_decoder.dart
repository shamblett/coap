/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

import 'package:typed_data/typed_data.dart';

import '../../coap_code.dart';
import '../../coap_constants.dart';
import '../../coap_empty_message.dart';
import '../../coap_message.dart';
import '../../coap_message_type.dart';
import '../../coap_option.dart';
import '../../coap_option_type.dart';
import '../../coap_request.dart';
import '../../coap_response.dart';
import '../message_decoder.dart';
import 'datagram_reader.dart';
import 'message_format.dart' as message_format;

/// Provides methods to parse incoming byte arrays to messages.
class UdpMessageDecoder implements MessageDecoder {
  /// Instantiates.
  UdpMessageDecoder();

  /// Parses the rest data other than protocol headers into the given message.
  @override
  CoapMessage? parseMessage(final Uint8Buffer data) {
    final reader = DatagramReader(data);

    final version = message_format.Version.decode(
      reader.read(message_format.Version.bitLength),
    );

    if (version == null) {
      return null;
    }

    final type = CoapMessageType.decode(reader.read(CoapMessageType.bitLength));

    if (type == null) {
      return null;
    }

    final tokenLength = reader.read(message_format.tokenLengthBits);
    final code = CoapCode.decode(reader.read(CoapCode.bitLength));

    if (code == null) {
      return null;
    }

    final id = reader.read(message_format.idBits);

    // Read token
    final Uint8Buffer token;
    if (tokenLength > 0) {
      token = reader.readBytes(tokenLength);
    } else {
      token = CoapConstants.emptyToken;
    }

    Uint8Buffer? payload;
    var hasUnknownCriticalOption = false;
    var hasFormatError = false;
    final options = <CoapOption>[];
    // Read options
    var currentOption = 0;
    while (reader.bytesAvailable) {
      final nextByte = reader.readNextByte();
      if (nextByte == message_format.payloadMarker) {
        if (!reader.bytesAvailable) {
          // The presence of a marker followed by a zero-length payload
          // must be processed as a message format error
          hasFormatError = true;
          break;
        }

        payload = reader.readBytesLeft();
      } else {
        // The first 4 bits of the byte represent the option delta
        final optionDeltaNibble = (0xF0 & nextByte) >> 4;
        final deltaValue = _getValueFromOptionNibble(
          optionDeltaNibble,
          reader,
        );

        if (deltaValue == null) {
          hasFormatError = true;
          break;
        }

        currentOption += deltaValue;

        // The second 4 bits represent the option length
        final optionLengthNibble = 0x0F & nextByte;
        final optionLength = _getValueFromOptionNibble(
          optionLengthNibble,
          reader,
        );

        if (optionLength == null) {
          hasFormatError = true;
          break;
        }

        // Read option
        final CoapOption opt;
        try {
          final optionType = OptionType.fromTypeNumber(currentOption);
          opt = CoapOption.create(optionType);
        } on UnknownElectiveOptionException catch (_) {
          // Unknown elective options must be silently ignored
          continue;
        } on UnknownCriticalOptionException catch (_) {
          // Messages with unknown critical options must be rejected
          hasUnknownCriticalOption = true;
          break;
        }
        opt.byteValue = reader.readBytes(optionLength);
        // Reverse byte order for numeric options
        if (opt.type.optionFormat == OptionFormat.integer) {
          opt.byteValue = Uint8Buffer()..addAll(opt.byteValue.reversed);
        }

        options.add(opt);
      }
    }

    if (code.isRequest) {
      return CoapRequest.fromParsed(
        id: id,
        type: type,
        coapCode: code,
        token: token,
        options: options,
        payload: payload,
        hasUnknownCriticalOption: hasUnknownCriticalOption,
        hasFormatError: hasFormatError,
      );
    } else if (code.isResponse) {
      return CoapResponse.fromParsed(
        id: id,
        type: type,
        coapCode: code,
        token: token,
        options: options,
        payload: payload,
        hasUnknownCriticalOption: hasUnknownCriticalOption,
        hasFormatError: hasFormatError,
      );
    } else if (code.isEmpty) {
      return CoapEmptyMessage.fromParsed(
        id: id,
        type: type,
        coapCode: code,
        token: token,
        options: options,
        payload: payload,
        hasUnknownCriticalOption: hasUnknownCriticalOption,
        hasFormatError: hasFormatError,
      );
    }

    return null;
  }

  /// Calculates the value used in the extended option fields as specified
  /// in RFC 7252, section 3.1.
  int? _getValueFromOptionNibble(
    final int nibble,
    final DatagramReader datagram,
  ) {
    if (nibble < 13) {
      return nibble;
    } else if (nibble == 13) {
      return datagram.read(8) + 13;
    } else if (nibble == 14) {
      return datagram.read(16) + 269;
    }

    return null;
  }
}
