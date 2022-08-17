/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

import 'package:collection/collection.dart';
import 'package:typed_data/typed_data.dart';

import '../../coap_code.dart';
import '../../coap_message.dart';
import '../../coap_message_type.dart';
import '../../coap_option.dart';
import '../../coap_option_type.dart';
import '../message_encoder.dart';
import 'datagram_writer.dart';
import 'message_format.dart' as message_format;

/// Provides methods to serialize outgoing messages to byte arrays.
class UdpMessageEncoder implements MessageEncoder {
  /// Encodes a CoAP message into a bytes array.
  /// Returns the encoded bytes, or null if the message can not be encoded,
  /// i.e. the message is not a Request, a Response or an EmptyMessage.
  @override
  Uint8Buffer serializeMessage(final CoapMessage message) {
    final writer = DatagramWriter();

    const version = message_format.Version.version1;
    const versionLength = message_format.Version.bitLength;
    final type = message.type;

    if (type == null) {
      throw const FormatException(
        'Message serialization failed due to undefined type.',
      );
    }

    // Write fixed-size CoAP headers
    writer
      ..write(version.numericValue, versionLength)
      ..write(type.code, CoapMessageType.bitLength)
      ..write(message.token?.length ?? 0, message_format.tokenLengthBits)
      ..write(message.code.code, CoapCode.bitLength)
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

    return writer.toByteArray();
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
