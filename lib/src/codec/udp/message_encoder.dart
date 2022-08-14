/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

import 'package:collection/collection.dart';
import 'package:typed_data/typed_data.dart';

import '../../coap_code.dart';
import '../../coap_empty_message.dart';
import '../../coap_message.dart';
import '../../coap_option.dart';
import '../../coap_option_type.dart';
import '../../coap_request.dart';
import '../../coap_response.dart';
import 'datagram_writer.dart';
import 'message_format.dart' as message_format;

/// Provides methods to serialize outgoing messages to byte arrays.
class CoapMessageEncoder {
  void serialize(
    final CoapDatagramWriter writer,
    final CoapMessage message,
    final int code,
  ) {
    // Write fixed-size CoAP headers
    writer
      ..write(message_format.version, message_format.versionBits)
      ..write(message.type?.code, message_format.typeBits)
      ..write(message.token?.length ?? 0, message_format.tokenLengthBits)
      ..write(code, message_format.codeBits)
      ..write(message.id, message_format.idBits)
      // Write token, which may be 0 to 8 bytes, given by token length field
      ..writeBytes(message.token);

    var lastOptionNumber = 0;
    final options = message.getAllOptions();
    insertionSort<CoapOption>(
      options,
      compare: (final a, final b) => a.type.compareTo(b.type),
    );

    for (final opt in options) {
      if (opt.type == OptionType.uriHost || opt.type == OptionType.uriPort) {
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

    if (message.payload != null && message.payload!.isNotEmpty) {
      // If payload is present and of non-zero length, it is prefixed by
      // an one-byte Payload Marker (0xFF) which indicates the end of
      // options and the start of the payload
      writer.writeByte(message_format.payloadMarker);
    }
    // Write payload
    writer.writeBytes(message.payload);
  }

  /// Encodes a request into a bytes array.
  Uint8Buffer encodeRequest(final CoapRequest request) {
    final writer = CoapDatagramWriter();
    serialize(writer, request, request.code.code);
    return writer.toByteArray();
  }

  /// Encodes a response into a bytes array.
  Uint8Buffer encodeResponse(final CoapResponse response) {
    final writer = CoapDatagramWriter();
    serialize(writer, response, response.code.code);
    return writer.toByteArray();
  }

  /// Encodes an empty message into a bytes array.
  Uint8Buffer encodeEmpty(final CoapEmptyMessage message) {
    final writer = CoapDatagramWriter();
    serialize(writer, message, CoapCode.empty.code);
    return writer.toByteArray();
  }

  /// Encodes a CoAP message into a bytes array.
  /// Returns the encoded bytes, or null if the message can not be encoded,
  /// i.e. the message is not a Request, a Response or an EmptyMessage.
  Uint8Buffer encodeMessage(final CoapMessage message) {
    if (message.isRequest) {
      return encodeRequest(message as CoapRequest);
    } else if (message.isResponse) {
      return encodeResponse(message as CoapResponse);
    } else if (message.isEmpty) {
      //A ping message is empty, but it is a request message so check for this
      if (message is CoapRequest) {
        return encodeRequest(message);
      } else {
        return encodeEmpty(message as CoapEmptyMessage);
      }
    } else {
      // TODO(JKRhb): Get rid of error via an enum.
      throw StateError('Encoding error: Unknown message type.');
    }
  }

  /// Returns the 4-bit option header value.
  static int _getOptionNibble(final int optionValue) {
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
}
