/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

// ignore_for_file: omit_local_variable_types
// ignore_for_file: unnecessary_final
// ignore_for_file: cascade_invocations
// ignore_for_file: avoid_print
// ignore_for_file: avoid_types_on_closure_parameters
// ignore_for_file: avoid_returning_this
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes
// ignore_for_file: prefer_null_aware_operators
// ignore_for_file: avoid_annotating_with_dynamic

/// Message decoder 03
class CoapMessageDecoder03 extends CoapMessageDecoder {
  /// Construction
  CoapMessageDecoder03(typed.Uint8Buffer data) : super(data) {
    readProtocol();
  }

  int _optionCount;

  @override
  bool get isWellFormed => _version == CoapDraft03.version;

  @override
  void readProtocol() {
    // Read headers
    _version = _reader.read(CoapDraft03.versionBits);
    _type = _reader.read(CoapDraft03.typeBits);
    _optionCount = _reader.read(CoapDraft03.optionCountBits);
    _code = CoapDraft03.mapInCode(_reader.read(CoapDraft03.codeBits));
    _id = _reader.read(CoapDraft03.idBits);
  }

  @override
  void parseMessage(CoapMessage message) {
    // Read options
    int currentOption = 0;
    for (int i = 0; i < _optionCount; i++) {
      // Read option delta bits
      final int optionDelta = _reader.read(CoapDraft03.optionDeltaBits);

      currentOption += optionDelta;
      final int currentOptionType = CoapDraft03.getOptionType(currentOption);

      if (CoapDraft03.isFencepost(currentOption)) {
        // Read number of options
        _reader.read(CoapDraft03.optionLengthBaseBits);
      } else {
        // Read option length
        int length = _reader.read(CoapDraft03.optionLengthBaseBits);
        if (length > CoapDraft03.maxOptionLengthBase) {
          // Read extended option length
          length += _reader.read(CoapDraft03.optionLengthExtendedBits);
        }
        // Read option
        CoapOption opt = CoapOption.create(currentOptionType);
        opt.valueBytes = _reader.readBytes(length);

        if (opt.type == optionTypeContentType) {
          final int ct = opt.intValue;
          final int ct2 = CoapDraft03.mapInMediaType(ct);
          if (ct != ct2) {
            opt = CoapOption.createVal(currentOptionType, ct2);
          }
        }

        message.addOption(opt);
      }
    }

    message.token ??= CoapConstants.emptyToken;

    message.payload = _reader.readBytesLeft();
  }
}
