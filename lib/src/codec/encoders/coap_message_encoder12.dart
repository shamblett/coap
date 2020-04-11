/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Message encoder 12
class CoapMessageEncoder12 extends CoapMessageEncoder {
  final CoapILogger _log = CoapLogManager().logger;

  @override
  void serialize(CoapDatagramWriter writer, CoapMessage message, int code) {
    final optWriter = CoapDatagramWriter();
    var optionCount = 0;
    var lastOptionNumber = 0;

    final List<CoapOption> options = message.getAllOptions();
    if (message.token != null &&
        message.token.isNotEmpty &&
        !message.hasOption(optionTypeToken)) {
      options.add(CoapOption.createRaw(optionTypeToken, message.token));
    }
    CoapUtil.insertionSort(
        options, (dynamic a, dynamic b) => a.type.compareTo(b.type));

    for (final opt in options) {
      if (opt.isDefault()) {
        continue;
      }
      final opt2 = opt;

      final optNum = CoapDraft12.getOptionNumber(opt2.type);
      var optionDelta = optNum - lastOptionNumber;

      // The Option Jump mechanism is used when the delta to the next option
      // number is larger than 14.
      while (optionDelta > CoapDraft12.maxOptionDelta) {
        // For the formats that include an Option Jump Value, the actual
        // addition to the current Option number is computed as follows:
        // Delta = ((Option Jump Value) + N) * 8 where N is 2 for the
        // one-byte version and N is 258 for the two-byte version.
        if (optionDelta < 30) {
          optWriter.write(0xF1, CoapDraft12.singleOptionJumpBits);
          optionDelta -= 15;
        } else if (optionDelta < 2064) {
          final optionJumpValue = (optionDelta ~/ 8) - 2;
          optionDelta -= (optionJumpValue + 2) * 8;
          optWriter.write(0xF2, CoapDraft12.singleOptionJumpBits);
          optWriter.write(optionJumpValue, CoapDraft12.singleOptionJumpBits);
        } else if (optionDelta < 526359) {
          optionDelta = min(optionDelta, 526344); // Limit to avoid overflow
          final optionJumpValue = (optionDelta ~/ 8) - 258;
          optionDelta -= (optionJumpValue + 258) * 8;
          optWriter.write(0xF3, CoapDraft12.singleOptionJumpBits);
          optWriter.write(
              optionJumpValue, 2 * CoapDraft12.singleOptionJumpBits);
        } else {
          _log.error('Option delta too large. Actual delta: $optionDelta');
        }
      }

      // Write option delta
      optWriter.write(optionDelta, CoapDraft12.optionDeltaBits);

      // Write option length
      final length = opt2.length;
      if (length <= CoapDraft12.maxOptionLengthBase) {
        // Use option length base field only to encode
        // option lengths less or equal than MAX_OPTIONLENGTH_BASE
        optWriter.write(length, CoapDraft12.optionLengthBaseBits);
      } else if (length <= 1034) {
        // When the Length field is set to 15, another byte is added as
        // an 8-bit unsigned integer whose value is added to the 15,
        // allowing option value lengths of 15-270 bytes. For option
        // lengths beyond 270 bytes, we reserve the value 255 of an
        // extension byte to mean
        // 'add 255, read another extension byte'. Options that are
        // longer than 1034 bytes MUST NOT be sent
        optWriter.write(15, CoapDraft12.optionLengthBaseBits);

        final rounds = (length - 15) ~/ 255;
        for (var i = 0; i < rounds; i++) {
          optWriter.write(255, CoapDraft12.optionLengthExtendedBits);
        }
        final remainingLength = length - ((rounds * 255) + 15);
        optWriter.write(remainingLength, CoapDraft12.optionLengthExtendedBits);
      } else {
        _log.error(
            'Option length larger than allowed 1034. Actual length: $length');
      }

      // Write option value
      if (length > 0) {
        optWriter.writeBytes(opt2.valueBytes);
      }

      ++optionCount;
      lastOptionNumber = optNum;
    }

    // Write fixed-size CoAP headers
    writer.write(CoapDraft12.version, CoapDraft12.versionBits);
    writer.write(message.type, CoapDraft12.typeBits);
    if (optionCount < 15) {
      writer.write(optionCount, CoapDraft12.optionCountBits);
    } else {
      writer.write(15, CoapDraft12.optionCountBits);
    }
    writer.write(code, CoapDraft12.codeBits);
    writer.write(message.id, CoapDraft12.idBits);

    // Write options
    writer.writeBytes(optWriter.toByteArray());

    //Write payload
    writer.writeBytes(message.payload);
  }
}
