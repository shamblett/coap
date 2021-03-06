/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Message encoder 18
class CoapMessageEncoder18 extends CoapMessageEncoder {
  @override
  void serialize(CoapDatagramWriter writer, CoapMessage message, int? code) {
    // Write fixed-size CoAP headers
    writer.write(CoapDraft18.version, CoapDraft18.versionBits);
    writer.write(message.type, CoapDraft18.typeBits);
    writer.write(message.token == null ? 0 : message.token!.length,
        CoapDraft18.tokenLengthBits);
    writer.write(code, CoapDraft18.codeBits);
    writer.write(message.id, CoapDraft18.idBits);

    // Write token, which may be 0 to 8 bytes, given by token length field
    writer.writeBytes(message.token);

    var lastOptionNumber = 0;
    final options = message.getAllOptions() as List<CoapOption>;
    CoapUtil.insertionSort(
        options, (dynamic a, dynamic b) => a.type.compareTo(b.type));

    for (final opt in options) {
      if (opt.type == optionTypeToken ||
          opt.type == optionTypeUriHost ||
          opt.type == optionTypeUriPort) {
        continue;
      }

      // Write 4-bit option delta
      final optNum = opt.type;
      final optionDelta = optNum - lastOptionNumber;
      final optionDeltaNibble = CoapDraft18.getOptionNibble(optionDelta);
      writer.write(optionDeltaNibble, CoapDraft18.optionDeltaBits);

      // Write 4-bit option length
      final optionLength = opt.length;
      final optionLengthNibble = CoapDraft18.getOptionNibble(optionLength);
      writer.write(optionLengthNibble, CoapDraft18.optionLengthBits);

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

      // Write option value
      writer.writeBytes(opt.valueBytes);

      lastOptionNumber = optNum;
    }

    if (message.payload != null && message.payload!.isNotEmpty) {
      // If payload is present and of non-zero length, it is prefixed by
      // an one-byte Payload Marker (0xFF) which indicates the end of
      // options and the start of the payload
      writer.writeByte(CoapDraft18.payloadMarker);
    }
    // Write payload
    writer.writeBytes(message.payload);
  }
}
