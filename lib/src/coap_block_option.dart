/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// This class describes the block options of the CoAP messages
class CoapBlockOption extends CoapOption {
  CoapBlockOption(int type) : super(type) {
    this.intValue = 0;
  }

  /// num - Block number
  /// szx - Block size
  /// m - More flag
  CoapBlockOption.fromParts(int type, int num, int szx, bool m) : super(type) {
    this.intValue = _encode(num, szx, m);
  }

  /// Sets block params.
  /// num - Block number
  /// szx - Block size
  /// m - More flag
  void setValue(int num, int szx, bool m) {
    this.intValue = _encode(num, szx, m);
  }

  /// Block number.
  int get num => this.intValue >> 4;

  set num(int num) => setValue(num, szx, m);

  /// Block size.
  int get szx => this.intValue & 0x7;

  set szx(int szx) => setValue(num, szx, m);

  /// More flag.
  bool get m => (this.intValue >> 3 & 0x1) != 0;

  set more(bool m) => setValue(num, szx, m);

  typed.Uint8Buffer get blockValueBytes => _compressValueBytes();

  /// Gets the real block size which is 2 ^ (SZX + 4).
  static int decodeSZX(int szx) {
    return 1 << (szx + 4);
  }

  /// Gets the decoded block size in bytes (B).
  int size() {
    return decodeSZX(szx);
  }

  /// Converts a block size into the corresponding SZX.
  static int encodeSZX(int blockSize) {
    if (blockSize < 16) return 0;
    if (blockSize > 1024) return 6;
    return ((log(blockSize) / log(2)) - 4).toInt();
  }

  /// Checks whether the given SZX is valid or not.
  static bool validSZX(int szx) {
    return (szx >= 0 && szx <= 6);
  }

  static int _encode(int num, int szx, bool m) {
    int value = 0;
    value |= (szx & 0x7);
    value |= (m ? 1 : 0) << 3;
    value |= num << 4;
    return value;
  }

  /// Strips leading zeros for 32 bit integers
  typed.Uint8Buffer _compressValueBytes() {
    if (_valueBytes.length == 4) {
      if (_valueBytes[3] == 0) {
        return new typed.Uint8Buffer()
          ..addAll(_valueBytes.take(3).toList());
      }
    }
    return _valueBytes;
  }
}
