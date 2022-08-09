import 'dart:typed_data';

import 'package:typed_data/typed_data.dart';

import 'coap_option_type.dart';
import 'option.dart';

// TODO(JKRhb): This currently can only contain encoded values and does not
//              provide any real functionality.
class OscoreOptionValue {
  OscoreOptionValue(this.partialIV, this.kid, this.kidContext)
      : byteValue = _encodeOscoreOptionValue(partialIV, kid, kidContext);

  static const int _flagBitsByteLength = 1;
  static const int _kidContextLengthByteLength = 1;

  OscoreOptionValue.parse(this.byteValue)
      : partialIV = _parsepartialIV(byteValue),
        kid = _parseKid(byteValue),
        kidContext = _parseKidContext(byteValue);

  // TODO(JKRhb): Maybe this can be done more elegantly
  static Uint8List _encodeInteger(final int integer) => Uint8List.fromList(
        Uint8List.sublistView(Uint64List.fromList([integer]))
            .take((integer / 8).ceil())
            .toList(),
      );

  static Uint8Buffer _encodeOscoreOptionValue(
    final int partialIV,
    final int? kid,
    final Uint8Buffer? kidContext,
  ) {
    final partialIVBytes = _encodeInteger(partialIV);
    Uint8List? kidBytes;

    if (kid != null) {
      kidBytes = _encodeInteger(kid);
    }

    const kidBitMask = 1 << 3;
    const kidContextBitMask = 1 << 4;

    final resultBuffer = Uint8Buffer();

    var flagByte = 0;

    if (kid != null) {
      flagByte = flagByte | kidBitMask;
    }

    if (kidContext != null) {
      flagByte = flagByte | kidContextBitMask;
    }

    if (partialIVBytes.lengthInBytes > 5) {
      throw ArgumentError.value(
        partialIV,
        '_encodeOscoreOptionValue',
        'too long (maximum length: 5 bytes)',
      );
    }

    if ((kidContext?.lengthInBytes ?? 0) > 255) {
      throw ArgumentError.value(
        kidContext,
        '_encodeOscoreOptionValue',
        'too long (maximum length: 255 bytes)',
      );
    }

    flagByte |= partialIVBytes.lengthInBytes;

    resultBuffer
      ..add(flagByte)
      ..addAll(partialIVBytes);

    if (kidContext != null) {
      resultBuffer
        ..add(kidContext.lengthInBytes)
        ..addAll(kidContext);
    }

    if (kidBytes != null) {
      resultBuffer.addAll(kidBytes);
    }

    return resultBuffer;
  }

  static int _parsepartialIV(final Uint8Buffer bytes) {
    final length = _parsePartialIVLength(bytes);
    return Uint64List.fromList(
      Uint8Buffer()..addAll(bytes.getRange(1, length + 1)),
    )[0];
  }

  static int _parsePartialIVLength(final Uint8Buffer bytes) {
    const bitmask = (1 << 3) - 1;
    return bytes.first & bitmask;
  }

  static bool _parseFlag(final Uint8Buffer bytes, final int bitNumber) {
    final bitmask = 1 << bitNumber;
    return (bytes.first & bitmask) == 1;
  }

  static int? _parseKid(final Uint8Buffer bytes) {
    if (!_hasKid(bytes)) {
      return null;
    }

    var offset = _flagBitsByteLength + _parsePartialIVLength(bytes);
    if (_hasKidContext(bytes)) {
      offset =
          offset + _kidContextLengthByteLength + _parseKidContextLength(bytes);
    }

    return Uint64List.fromList(
      Uint8Buffer()..addAll(bytes.skip(offset)),
    )[0];
  }

  static int _parseKidContextLength(final Uint8Buffer bytes) {
    if (!_hasKidContext(bytes)) {
      return 0;
    }

    final offset = _flagBitsByteLength + _parsePartialIVLength(bytes);

    return bytes.elementAt(offset);
  }

  static bool _hasKid(final Uint8Buffer bytes) => _parseFlag(bytes, 4);
  static bool _hasKidContext(final Uint8Buffer bytes) => _parseFlag(bytes, 5);

  static Uint8Buffer? _parseKidContext(final Uint8Buffer bytes) {
    if (!_hasKidContext(bytes)) {
      return null;
    }

    final offset = _flagBitsByteLength +
        _parsePartialIVLength(bytes) +
        _kidContextLengthByteLength;
    final kidContextLength = _parseKidContextLength(bytes);

    return Uint8Buffer()
      ..addAll(bytes.getRange(offset, offset + kidContextLength));
  }

  final Uint8Buffer byteValue;

  final int partialIV;

  final int? kid;

  final Uint8Buffer? kidContext;
}

class OscoreOption extends Option<OscoreOptionValue>
    implements OscoreOptionClassU {
  OscoreOption(this.value);

  OscoreOption.parse(final Uint8Buffer bytes)
      : value = OscoreOptionValue.parse(bytes);

  @override
  final OscoreOptionValue value;

  @override
  Uint8Buffer get byteValue => value.byteValue;

  @override
  final optionFormat = OptionFormat.oscore;

  @override
  final OptionType type = OptionType.oscore;

  @override
  String get valueString => value.toString();
}
