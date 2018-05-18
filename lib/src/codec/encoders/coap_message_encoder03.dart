/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

class CoapMessageEncoder03 extends CoapMessageEncoder {
  static CoapILogger _log = new CoapLogManager("console").logger;

  void serialize(CoapDatagramWriter writer, CoapMessage msg, int code) {
    final CoapDatagramWriter optWriter = new CoapDatagramWriter();
    int optionCount = 0;
    int lastOptionNumber = 0;

    final List<CoapOption> options = msg.getSortedOptions();
    if (msg.token != null &&
        msg.token.length > 0 &&
        !msg.hasOption(optionTypeToken)) {
      options.add(CoapOption.createRaw(optionTypeToken, msg.token));
    }
    CoapUtil.insertionSort(options, (a, b) => a.type.compareTo(b.type));

    for (CoapOption opt in options) {
      if (opt.isDefault()) continue;

      CoapOption opt2 = opt;

      final int optNum = CoapDraft03.getOptionNumber(opt2.type);
      int optionDelta = optNum - lastOptionNumber;

      // ensure that option delta value can be encoded correctly
      while (optionDelta > CoapDraft03.maxOptionDelta) {
        // Option delta is too large to be encoded:
        // add fencepost options in order to reduce the option delta
        // get fencepost option that is next to the last option
        final int fencepostNumber = CoapDraft03.nextFencepost(lastOptionNumber);

        // Calculate fencepost delta
        final int fencepostDelta = fencepostNumber - lastOptionNumber;
        if (fencepostDelta <= 0) {
          _log.warn("Fencepost liveness violated: delta = $fencepostDelta");
        }
        if (fencepostDelta > CoapDraft03.maxOptionDelta) {
          _log.warn("Fencepost safety violated: delta = $fencepostDelta");
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
        final int ct = opt2.intValue;
        final int ct2 = CoapDraft03.mapOutMediaType(ct);
        if (ct != ct2) opt2 = CoapOption.createVal(opt2.type, ct2);
      }

      // Write option length
      final int length = opt2.length;
      if (length <= CoapDraft03.maxOptionLengthBase) {
        // Use option length base field only to encode
        // option lengths less or equal than MAX_OPTIONLENGTH_BASE
        optWriter.write(length, CoapDraft03.optionLengthBaseBits);
      } else {
        // Use both option length base and extended field
        // to encode option lengths greater than MAX_OPTIONLENGTH_BASE
        final int baseLength = CoapDraft03.maxOptionLengthBase + 1;
        optWriter.write(baseLength, CoapDraft03.optionLengthBaseBits);

        final int extLength = length - baseLength;
        optWriter.write(extLength, CoapDraft03.optionLengthExtendedBits);
      }

      // Write option value
      optWriter.writeBytes(opt2.valueBytes);

      ++optionCount;
      lastOptionNumber = optNum;
    }

    // Write fixed-size CoAP headers
    writer.write(CoapDraft03.version, CoapDraft03.versionBits);
    writer.write(msg.type, CoapDraft03.typeBits);
    writer.write(optionCount, CoapDraft03.optionCountBits);
    writer.write(CoapDraft03.mapOutCode(code), CoapDraft03.codeBits);
    writer.write(msg.id, CoapDraft03.idBits);

    // Write options
    writer.writeBytes(optWriter.toByteArray());

    //Write payload
    writer.writeBytes(msg.payload);
  }
}
