/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Message encoder RFC 7252
class CoapMessageEncoderRfc7252 extends CoapMessageEncoder {
  @override
  void serialize(CoapDatagramWriter writer, CoapMessage message, int code) {
    // Write fixed-size CoAP headers
    writer.write(CoapRfc7252.version, CoapRfc7252.versionBits);
    writer.write(message.type, CoapRfc7252.typeBits);
    writer.write(message.token?.length ?? 0, CoapRfc7252.tokenLengthBits);
    writer.write(code, CoapRfc7252.codeBits);
    writer.write(message.id, CoapRfc7252.idBits);

    // Write token, which may be 0 to 8 bytes, given by token length field
    writer.writeBytes(message.token);

    var lastOptionNumber = 0;
    final options = message.getAllOptions() as List<CoapOption>;
    CoapUtil.insertionSort(
        options, (dynamic a, dynamic b) => a.type.compareTo(b.type));

    for (final opt in options) {
      if (opt.type == optionTypeUriHost || opt.type == optionTypeUriPort) {
        continue;
      }

      // Write 4-bit option delta
      final optNum = opt.type;
      final optionDelta = optNum - lastOptionNumber;
      final optionDeltaNibble = CoapRfc7252.getOptionNibble(optionDelta);
      writer.write(optionDeltaNibble, CoapRfc7252.optionDeltaBits);

      // Write 4-bit option length
      final optionLength = opt.length;
      final optionLengthNibble = CoapRfc7252.getOptionNibble(optionLength);
      writer.write(optionLengthNibble, CoapRfc7252.optionLengthBits);

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
      if (CoapOption.getFormatByType(opt.type) == OptionFormat.integer) {
        final valueBytes = opt.valueBytes;
        if (valueBytes != null) {
          final reversedBytes = valueBytes.reversed;
          final reversedBuffer = typed.Uint8Buffer()..addAll(reversedBytes);
          writer.writeBytes(reversedBuffer);
        }
      } else {
        writer.writeBytes(opt.valueBytes);
      }

      lastOptionNumber = optNum;
    }

    if (message.payload != null && message.payload!.isNotEmpty) {
      // If payload is present and of non-zero length, it is prefixed by
      // an one-byte Payload Marker (0xFF) which indicates the end of
      // options and the start of the payload
      writer.writeByte(CoapRfc7252.payloadMarker);
    }
    // Write payload
    writer.writeBytes(message.payload);
  }
}
