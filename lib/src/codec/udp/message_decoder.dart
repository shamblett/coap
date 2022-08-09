/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

import 'dart:typed_data';

import 'package:typed_data/typed_data.dart';

import '../../coap_code.dart';
import '../../coap_empty_message.dart';
import '../../coap_message.dart';
import '../../coap_message_type.dart';
import '../../coap_request.dart';
import '../../coap_response.dart';
import '../../option/coap_option_type.dart';
import '../../option/option.dart';
import 'datagram_reader.dart';
import 'message_format.dart' as message_format;

/// Decodes a CoAP UDP or DTLS message from a bytes array.
///
/// Returns the deserialized message, or `null` if the message can not be
/// decoded, i.e. the bytes do not represent a [CoapRequest], a [CoapResponse]
/// or a [CoapEmptyMessage].
CoapMessage? deserializeUdpMessage(final Uint8Buffer data) {
  final reader = DatagramReader(data);
  var hasFormatError = false;

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

  var token = _readToken(tokenLength, reader);
  if (token == null) {
    token = Uint8Buffer();
    hasFormatError = true;
  }

  Uint8Buffer? payload;
  var hasUnknownCriticalOption = false;
  final options = <Option<Object?>>[];
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
      try {
        final optionType = OptionType.fromTypeNumber(currentOption);
        var optionBytes = reader.readBytes(optionLength);
        if (Endian.host == Endian.little &&
            optionType.optionFormat is OptionFormat<int>) {
          optionBytes = Uint8Buffer()..addAll(optionBytes.reversed);
        }
        final option = optionType.parse(optionBytes);
        options.add(option);
      } on UnknownElectiveOptionException catch (_) {
        // Unknown elective options must be silently ignored
        continue;
      } on UnknownCriticalOptionException catch (_) {
        // Messages with unknown critical options must be rejected
        hasUnknownCriticalOption = true;
        break;
      }
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

Uint8Buffer? _readToken(final int? tokenLength, final DatagramReader reader) {
  if (tokenLength == null) {
    return null;
  }

  if (tokenLength > 0 && tokenLength < 15) {
    final actualTokenLength = _readExtendedTokenLength(tokenLength, reader);

    if (actualTokenLength != null) {
      return reader.readBytes(actualTokenLength);
    }
  }

  return null;
}

/// Read a potentially extended token length as specified in
/// [RFC 8974, section 2.1].
///
/// [RFC 8974, section 2.1]: https://datatracker.ietf.org/doc/html/rfc8974#section-2.1
int? _readExtendedTokenLength(
  final int tokenLength,
  final DatagramReader reader,
) =>
    _readExtendedLength(tokenLength, reader);

/// Calculates the value used in the extended option fields as specified
/// in RFC 7252, section 3.1.
int? _getValueFromOptionNibble(
  final int nibble,
  final DatagramReader datagram,
) =>
    _readExtendedLength(nibble, datagram);

int? _readExtendedLength(
  final int value,
  final DatagramReader datagram,
) {
  if (value < 13) {
    return value;
  } else if (value == 13) {
    return datagram.read(8) + 13;
  } else if (value == 14) {
    return datagram.read(16) + 269;
  }

  return null;
}
