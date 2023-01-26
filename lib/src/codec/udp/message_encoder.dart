/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:typed_data/typed_data.dart';

import '../../coap_code.dart';
import '../../coap_constants.dart';
import '../../coap_message.dart';
import '../../coap_message_type.dart';
import '../../coap_request.dart';
import '../../option/coap_option_type.dart';
import '../../option/integer_option.dart';
import '../../option/option.dart';
import '../../option/string_option.dart';
import 'datagram_writer.dart';
import 'message_format.dart' as message_format;

/// Encodes a CoAP UDP or DTLS message into a bytes array.
/// Returns the encoded bytes, or null if the message can not be encoded,
/// i.e. the message is not a Request, a Response or an EmptyMessage.
Uint8Buffer serializeUdpMessage(final CoapMessage message) {
  final writer = DatagramWriter();

  const version = message_format.Version.version1;
  const versionLength = message_format.Version.bitLength;

  // Write fixed-size CoAP headers
  writer
    ..write(version.numericValue, versionLength)
    ..write(message.type.code, CoapMessageType.bitLength);

  final token = message.token;
  final tokenLength = _getTokenLength(token);

  writer
    ..write(tokenLength, message_format.tokenLengthBits)
    ..write(message.code.code, CoapCode.bitLength)
    ..write(message.id, message_format.idBits);

  if (token != null) {
    _writeExtendedTokenLength(writer, tokenLength, token);
  }

  // Write token, which may be 0 to 8 bytes or have an extended token length,
  // given by token length and the extended token length field.
  writer.writeBytes(token);

  var lastOptionNumber = 0;
  final options = message.getAllOptions();
  insertionSort<Option<Object?>>(
    options,
    compare: (final a, final b) => a.type.compareTo(b.type),
  );

  for (final opt in options) {
    if (_shouldBeSkipped(opt, message)) {
      continue;
    }

    // Write 4-bit option delta
    final optNum = opt.type.optionNumber;
    final optionDelta = optNum - lastOptionNumber;
    final optionDeltaNibble = _getOptionNibble(optionDelta);
    writer.write(optionDeltaNibble, message_format.optionDeltaBits);

    // Write 4-bit option length
    final optionLength = opt.length;
    final optionLengthNibble = _getOptionNibble(optionLength);
    writer.write(optionLengthNibble, message_format.optionLengthBits);

    // Write extended option delta field (0 - 2 bytes)
    if (optionDeltaNibble == 13) {
      writer.write(optionDelta - 13, 8);
    } else if (optionDeltaNibble == 14) {
      writer.write(optionDelta - 269, 16);
    }

    // Write extended option length field (0 - 2 bytes)
    if (optionLengthNibble == 13) {
      writer.write(optionLength - 13, 8);
    } else if (optionLengthNibble == 14) {
      writer.write(optionLength - 269, 16);
    }

    // Write option value, reverse byte order for numeric options
    if (opt.type.optionFormat == OptionFormat.integer) {
      final reversedBuffer = Uint8Buffer()..addAll(opt.byteValue.reversed);
      writer.writeBytes(reversedBuffer);
    } else {
      writer.writeBytes(opt.byteValue);
    }

    lastOptionNumber = optNum;
  }

  if (message.payload.isNotEmpty) {
    // If payload is present and of non-zero length, it is prefixed by
    // an one-byte Payload Marker (0xFF) which indicates the end of
    // options and the start of the payload
    writer.writeByte(message_format.payloadMarker);
  }
  // Write payload
  writer.writeBytes(message.payload);

  return writer.toByteArray();
}

bool _shouldBeSkipped(final Option<Object?> opt, final CoapMessage message) {
  if (opt is UriHostOption &&
      InternetAddress.tryParse(opt.value) == message.destination) {
    return true;
  }

  if (opt is UriPortOption && message is CoapRequest) {
    return _usesDefaultPort(message.scheme, opt.value);
  }

  return false;
}

bool _usesDefaultPort(final String? scheme, final int port) =>
    scheme == CoapConstants.uriScheme && port == CoapConstants.defaultPort ||
    scheme == CoapConstants.secureUriScheme &&
        port == CoapConstants.defaultSecurePort;

/// Determine the token length.
///
/// The token length can either be of zero to eight bytes or be extended,
/// following [RFC 8974].
///
/// [RFC 8974]: https://datatracker.ietf.org/doc/html/rfc8974
int _getTokenLength(final Uint8Buffer? token) {
  final tokenLength = token?.length ?? 0;
  if (tokenLength <= 12) {
    return tokenLength;
  } else if (tokenLength <= 255 + 13) {
    return 13;
  } else if (tokenLength <= 65535 + 269) {
    return 14;
  } else {
    throw FormatException('Unsupported token length delta $tokenLength');
  }
}

/// Write a potentially extended token length as specified in [RFC 8974].
///
/// [RFC 8974]: https://datatracker.ietf.org/doc/html/rfc8974
void _writeExtendedTokenLength(
  final DatagramWriter writer,
  final int tokenLength,
  final Uint8Buffer token,
) {
  final extendedTokenLength = _getExtendedTokenLength(tokenLength, token);

  switch (tokenLength) {
    case 13:
      writer.write(extendedTokenLength, 8);
      break;
    case 14:
      writer.write(extendedTokenLength, 16);
  }
}

/// Determine a potentially extended token length as specified in [RFC 8974].
///
/// [RFC 8974]: https://datatracker.ietf.org/doc/html/rfc8974
int _getExtendedTokenLength(
  final int tokenLength,
  final Uint8Buffer token,
) {
  switch (tokenLength) {
    case 13:
      return token.length - 13;
    case 14:
      return token.length - 269;
  }

  return 0;
}

/// Returns the 4-bit option header value.
int _getOptionNibble(final int optionValue) {
  if (optionValue <= 12) {
    return optionValue;
  } else if (optionValue <= 255 + 13) {
    return 13;
  } else if (optionValue <= 65535 + 269) {
    return 14;
  } else {
    throw FormatException('Unsupported option delta $optionValue');
  }
}
