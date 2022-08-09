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
    implements OscoreOptionClassE, OscoreOptionClassU {
  /// Base construction
  CoapBlockOption(
    final BlockOptionType blockOptionType,
    final int value,
  ) : super(blockOptionType.optionType, value);

  CoapBlockOption.parse(
    final BlockOptionType blockOptionType,
    final Uint8Buffer bytes,
  ) : super.parse(blockOptionType.optionType, bytes);

  /// num - Block number
  /// szx - Block size
  /// m - More flag
  CoapBlockOption.fromParts(
    final BlockOptionType blockOptionType,
    final int num,
    final int szx, {
    final bool m = false,
  }) : super(blockOptionType.optionType, _encode(num, szx, m));

  int get rawValue => num;

  /// Block number.
  int get num => value >> 4;

  /// Block size.
  int get szx => value & 0x7;

  /// More flag.
  bool get m => (value >> 3 & 0x1) != 0;

  /// Block bytes
  Uint8Buffer get blockValueBytes => _compressValueBytes();

  /// Gets the real block size which is 2 ^ (SZX + 4).
  static int decodeSZX(final int szx) => 1 << (szx + 4);

  /// Gets the decoded block size in bytes (B).
  int size() => decodeSZX(szx);

  /// Converts a block size into the corresponding SZX.
  static int encodeSZX(final int blockSize) {
    if (blockSize < 16) {
      return 0;
    }
    if (blockSize > 1024) {
      return 6;
    }
    return ((log(blockSize) / log(2)) - 4).toInt();
  }

  /// Checks whether the given SZX is valid or not.
  static bool validSZX(final int szx) => szx >= 0 && szx <= 6;

  @override
  String toString() => 'Raw value: $value, num: $num, szx: $szx, more: $m';

  static int _encode(final int num, final int szx, final bool m) {
    var value = 0;
    value |= szx & 0x7;
    value |= (m ? 1 : 0) << 3;
    value |= num << 4;
    return value;
  }

  /// Strips leading zeros for 32 bit integers
  Uint8Buffer _compressValueBytes() {
    if (byteValue.length == 4) {
      if (byteValue[3] == 0) {
        return Uint8Buffer()..addAll(byteValue.take(3).toList());
      }
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
    final int szx, {
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
    final int szx, {
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
    final int szx, {
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
    final int szx, {
    final bool m = false,
  }) : super.fromParts(BlockOptionType.qBlock1, num, szx, m: m);
}
