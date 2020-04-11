/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Message encoder 03
class CoapMessageEncoder03 extends CoapMessageEncoder {
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
      var opt2 = opt;

      final optNum = CoapDraft03.getOptionNumber(opt2.type);
      var optionDelta = optNum - lastOptionNumber;

      // ensure that option delta value can be encoded correctly
      while (optionDelta > CoapDraft03.maxOptionDelta) {
        // Option delta is too large to be encoded:
        // add fencepost options in order to reduce the option delta
        // get fencepost option that is next to the last option
        final fencepostNumber = CoapDraft03.nextFencepost(lastOptionNumber);

        // Calculate fencepost delta
        final fencepostDelta = fencepostNumber - lastOptionNumber;
        if (fencepostDelta <= 0) {
          _log.warn('Fencepost liveness violated: delta = $fencepostDelta');
        }
        if (fencepostDelta > CoapDraft03.maxOptionDelta) {
          _log.warn('Fencepost safety violated: delta = $fencepostDelta');
        }

        // Write fencepost option delta
        optWriter.write(fencepostDelta, CoapDraft03.optionDeltaBits);
        // Fencepost have an empty value
        optWriter.write(0, CoapDraft03.optionLengthBaseBits);

        ++optionCount;
        lastOptionNumber = fencepostNumber;
        optionDelta -= fencepostDelta;
      }

      // Write option delta
      optWriter.write(optionDelta, CoapDraft03.optionDeltaBits);

      if (opt2.type == optionTypeContentType) {
        final ct = opt2.intValue;
        final ct2 = CoapDraft03.mapOutMediaType(ct);
        if (ct != ct2) {
          opt2 = CoapOption.createVal(opt2.type, ct2);
        }
      }

      // Write option length
      final length = opt2.length;
      if (length <= CoapDraft03.maxOptionLengthBase) {
        // Use option length base field only to encode
        // option lengths less or equal than MAX_OPTIONLENGTH_BASE
        optWriter.write(length, CoapDraft03.optionLengthBaseBits);
      } else {
        // Use both option length base and extended field
        // to encode option lengths greater than MAX_OPTIONLENGTH_BASE
        const baseLength = CoapDraft03.maxOptionLengthBase + 1;
        optWriter.write(baseLength, CoapDraft03.optionLengthBaseBits);

        final extLength = length - baseLength;
        optWriter.write(extLength, CoapDraft03.optionLengthExtendedBits);
      }

      // Write option value
      optWriter.writeBytes(opt2.valueBytes);

      ++optionCount;
      lastOptionNumber = optNum;
    }

    // Write fixed-size CoAP headers
    writer.write(CoapDraft03.version, CoapDraft03.versionBits);
    writer.write(message.type, CoapDraft03.typeBits);
    writer.write(optionCount, CoapDraft03.optionCountBits);
    writer.write(CoapDraft03.mapOutCode(code), CoapDraft03.codeBits);
    writer.write(message.id, CoapDraft03.idBits);

    // Write options
    writer.writeBytes(optWriter.toByteArray());

    //Write payload
    writer.writeBytes(message.payload);
  }
}
