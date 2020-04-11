/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// This class describes the block options of the CoAP messages
class CoapBlockOption extends CoapOption {
  /// Base construction
  CoapBlockOption(int type) : super(type) {
    intValue = 0;
  }

  /// num - Block number
  /// szx - Block size
  /// m - More flag
  CoapBlockOption.fromParts(int type, int num, int szx, {bool m = false})
      : super(type) {
    intValue = _encode(num, szx, m);
  }

  /// Sets block params.
  /// num - Block number
  /// szx - Block size
  /// m - More flag
  void setValue(int num, int szx, {bool m}) {
    intValue = _encode(num, szx, m);
  }

  /// Set the raw value directly
  set rawValue(int num) => intValue = num;

  /// Block number.
  int get num => intValue >> 4;

  set num(int num) => setValue(num, szx, m: m);

  /// Block size.
  int get szx => intValue & 0x7;

  set szx(int szx) => setValue(num, szx, m: m);

  /// More flag.
  bool get m => (intValue >> 3 & 0x1) != 0;

  /// More flag.
  set more(bool m) => setValue(num, szx, m: m);

  /// Block bytes
  typed.Uint8Buffer get blockValueBytes => _compressValueBytes();

  /// Gets the real block size which is 2 ^ (SZX + 4).
  static int decodeSZX(int szx) => 1 << (szx + 4);

  /// Gets the decoded block size in bytes (B).
  int size() => decodeSZX(szx);

  /// Converts a block size into the corresponding SZX.
  static int encodeSZX(int blockSize) {
    if (blockSize < 16) {
      return 0;
    }
    if (blockSize > 1024) {
      return 6;
    }
    return ((log(blockSize) / log(2)) - 4).toInt();
  }

  /// Checks whether the given SZX is valid or not.
  static bool validSZX(int szx) => szx >= 0 && szx <= 6;

  @override
  String toString() => 'Raw value: $intValue, num: $num, szx: $szx, more: $m';

  static int _encode(int num, int szx, bool m) {
    var value = 0;
    value |= szx & 0x7;
    value |= (m ? 1 : 0) << 3;
    value |= num << 4;
    return value;
  }

  /// Strips leading zeros for 32 bit integers
  typed.Uint8Buffer _compressValueBytes() {
    if (valueBytes.length == 4) {
      if (valueBytes[3] == 0) {
        return typed.Uint8Buffer()..addAll(valueBytes.take(3).toList());
      }
    }
    return valueBytes;
  }
}
