/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Message encoder 8
class CoapMessageEncoder08 extends CoapMessageEncoder {
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

      final optNum = CoapDraft08.getOptionNumber(opt2.type);
      var optionDelta = optNum - lastOptionNumber;

      // ensure that option delta value can be encoded correctly
      while (optionDelta > CoapDraft08.maxOptionDelta) {
        // Option delta is too large to be encoded:
        // add fencepost options in order to reduce the option delta
        // get fencepost option that is next to the last option
        final fencepostNumber = CoapDraft08.nextFencepost(lastOptionNumber);

        // Calculate fencepost delta
        final fencepostDelta = fencepostNumber - lastOptionNumber;
        if (fencepostDelta <= 0) {
          _log.warn('Fencepost liveness violated: delta = $fencepostDelta');
        }
        if (fencepostDelta > CoapDraft08.maxOptionDelta) {
          _log.warn('Fencepost safety violated: delta = $fencepostDelta');
        }

        // Write fencepost option delta
        optWriter.write(fencepostDelta, CoapDraft08.optionDeltaBits);
        // Fencepost have an empty value
        optWriter.write(0, CoapDraft08.optionLengthBaseBits);

        ++optionCount;
        lastOptionNumber = fencepostNumber;
        optionDelta -= fencepostDelta;
      }

      // Write option delta
      optWriter.write(optionDelta, CoapDraft08.optionDeltaBits);

      // Write option length
      final length = opt2.length;
      if (length <= CoapDraft08.maxOptionLengthBase) {
        // Use option length base field only to encode
        // option lengths less or equal than MAX_OPTIONLENGTH_BASE
        optWriter.write(length, CoapDraft08.optionLengthBaseBits);
      } else {
        // Use both option length base and extended field
        // to encode option lengths greater than MAX_OPTIONLENGTH_BASE
        const baseLength = CoapDraft08.maxOptionLengthBase + 1;
        optWriter.write(baseLength, CoapDraft08.optionLengthBaseBits);

        final extLength = length - baseLength;
        optWriter.write(extLength, CoapDraft08.optionLengthExtendedBits);
      }

      // Write option value
      optWriter.writeBytes(opt2.valueBytes);

      ++optionCount;
      lastOptionNumber = optNum;
    }

    // Write fixed-size CoAP headers
    writer.write(CoapDraft08.version, CoapDraft08.versionBits);
    writer.write(message.type, CoapDraft08.typeBits);
    writer.write(optionCount, CoapDraft08.optionCountBits);
    writer.write(code, CoapDraft08.codeBits);
    writer.write(message.id, CoapDraft08.idBits);

    // Write options
    writer.writeBytes(optWriter.toByteArray());

    //Write payload
    writer.writeBytes(message.payload);
  }
}
