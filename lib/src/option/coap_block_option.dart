// ignore_for_file: no-magic-number

/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

import 'dart:math';

import 'package:typed_data/typed_data.dart';

import 'coap_option_type.dart';
import 'integer_option.dart';
import 'option.dart';

/// Enum representing the valid SZX values of [CoapBlockOption]s.
enum BlockSize {
  blockSize16(0),
  blockSize32(1),
  blockSize64(2),
  blockSize128(3),
  blockSize256(4),
  blockSize512(5),
  blockSize1024(6),
  reserved(7);

  /// Constructor
  const BlockSize(this.numericValue);

  /// The numeric SZX option value, represented by a single byte.
  ///
  /// Valid values are 0 to 6; 7 is reserved for future extensions.
  final int numericValue;

  static final Map<int, BlockSize> _registry = Map.fromEntries(
    values.map((final value) => MapEntry(value.numericValue, value)),
  );

  /// Creates a new [BlockSize] value from a decoded [blockSize] representation,
  /// rounding it to the nearest value.
  ///
  /// For instance, values between 0 and 16 will result in
  /// [BlockSize.blockSize16], values between 16 and 32 in
  /// [BlockSize.blockSize32], and so on.
  ///
  /// If a value greater than 1024 should be passed, an [ArgumentError] will be
  /// thrown.
  static BlockSize fromDecodedValue(final int blockSize) {
    final encodedValue = ((log(blockSize) / log(2)) - 4).toInt();
    return BlockSize.parse(encodedValue);
  }

  /// Creates a new [BlockSize] value from a valid [numericValue] (0-7).
  ///
  /// Throws an [ArgumentError] if the [numericValue] should be outside the
  /// allowed range 0 to 7.
  static BlockSize parse(final int numericValue) {
    final blockSize = _registry[numericValue];

    if (blockSize == null) {
      throw ArgumentError.value(numericValue);
    }

    return blockSize;
  }

  /// Decodes the [numericValue] of this [BlockSize].
  ///
  /// For example, 0 will return a decoded value of 16, 1 will return 32, and
  /// so on.
  int get decodedValue => 1 << (numericValue + 4);
}

enum BlockOptionType {
  block2(OptionType.block2),
  block1(OptionType.block1),
  qBlock2(OptionType.qBlock2),
  qBlock1(OptionType.qBlock1);

  const BlockOptionType(this.optionType);

  final OptionType optionType;
}

/// This class describes the block options of the CoAP messages
abstract class CoapBlockOption extends IntegerOption
    with OscoreOptionClassE, OscoreOptionClassU {
  /// Block number.
  int get num => value >> 4;

  /// Block size.
  BlockSize get szx => BlockSize.parse(value & 0x7);

  /// More flag.
  bool get m => (value >> 3 & 0x1) != 0;

  /// Block bytes
  Uint8Buffer get blockValueBytes => _compressValueBytes();

  /// Gets the decoded block size in bytes (B).
  int get size => szx.decodedValue;

  String get _szxErrorMessage =>
      'Encountered reserved SZX value 7 in CoapBlockOption.';

  /// Base construction
  CoapBlockOption(final BlockOptionType blockOptionType, final int value)
    : super(blockOptionType.optionType, value) {
    if (szx == BlockSize.reserved) {
      throw ArgumentError.value(szx, _szxErrorMessage);
    }
  }

  CoapBlockOption.parse(
    final BlockOptionType blockOptionType,
    final Uint8Buffer bytes,
  ) : super.parse(blockOptionType.optionType, bytes) {
    if (szx == BlockSize.reserved) {
      throw UnknownCriticalOptionException(optionNumber, _szxErrorMessage);
    }
  }

  /// num - Block number
  /// szx - Block size
  /// m - More flag
  CoapBlockOption.fromParts(
    final BlockOptionType blockOptionType,
    final int num,
    final BlockSize szx, {
    final bool m = false,
  }) : super(blockOptionType.optionType, _encode(num, szx, m));

  @override
  String toString() =>
      '$name: Raw value: $value, num: $num, szx: ${szx.numericValue}, more: $m';

  static int _encode(final int num, final BlockSize szx, final bool m) {
    var value = 0;
    value |= szx.numericValue & 0x7;
    value |= (m ? 1 : 0) << 3;
    value |= num << 4;
    return value;
  }

  /// Strips leading zeros for 32 bit integers
  Uint8Buffer _compressValueBytes() {
    if (byteValue.length == 4 && byteValue[3] == 0) {
      return Uint8Buffer()..addAll(byteValue.take(3).toList());
    }

    return byteValue;
  }
}

class Block2Option extends CoapBlockOption {
  Block2Option(final int rawValue) : super(BlockOptionType.block2, rawValue);

  Block2Option.parse(final Uint8Buffer bytes)
    : super.parse(BlockOptionType.block2, bytes);

  /// num - Block number
  /// szx - Block size
  /// m - More flag
  Block2Option.fromParts(
    final int num,
    final BlockSize szx, {
    final bool m = false,
  }) : super.fromParts(BlockOptionType.block2, num, szx, m: m);
}

class Block1Option extends CoapBlockOption {
  Block1Option(final int rawValue) : super(BlockOptionType.block1, rawValue);

  Block1Option.parse(final Uint8Buffer bytes)
    : super.parse(BlockOptionType.block1, bytes);

  /// num - Block number
  /// szx - Block size
  /// m - More flag
  Block1Option.fromParts(
    final int num,
    final BlockSize szx, {
    final bool m = false,
  }) : super.fromParts(BlockOptionType.block1, num, szx, m: m);
}

class QBlock2Option extends CoapBlockOption {
  QBlock2Option(final int rawValue) : super(BlockOptionType.qBlock2, rawValue);

  QBlock2Option.parse(final Uint8Buffer bytes)
    : super.parse(BlockOptionType.qBlock2, bytes);

  /// num - Block number
  /// szx - Block size
  /// m - More flag
  QBlock2Option.fromParts(
    final int num,
    final BlockSize szx, {
    final bool m = false,
  }) : super.fromParts(BlockOptionType.qBlock2, num, szx, m: m);
}

class QBlock1Option extends CoapBlockOption {
  QBlock1Option(final int rawValue) : super(BlockOptionType.qBlock1, rawValue);

  QBlock1Option.parse(final Uint8Buffer bytes)
    : super.parse(BlockOptionType.qBlock1, bytes);

  /// num - Block number
  /// szx - Block size
  /// m - More flag
  QBlock1Option.fromParts(
    final int num,
    final BlockSize szx, {
    final bool m = false,
  }) : super.fromParts(BlockOptionType.qBlock1, num, szx, m: m);
}
