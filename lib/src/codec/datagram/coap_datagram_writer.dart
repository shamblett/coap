/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// This class describes the functionality to write raw network-ordered
/// datagrams on bit-level.
class CoapDatagramWriter {
  /// Initializes a new DatagramWriter object
  CoapDatagramWriter() {
    _buffer = typed.Uint8Buffer();
    _currentByte = ByteData(1)..setUint8(0, 0);
    _currentBitIndex = 7;
  }

  final CoapILogger _log = CoapLogManager().logger;

  typed.Uint8Buffer _buffer;
  ByteData _currentByte;
  int _currentBitIndex;

  /// Writes a sequence of bits to the stream
  void write(int data, int numBits) {
    if (numBits < 32 && data >= (1 << numBits)) {
      _log.warn('Truncating value {$data} to {$numBits}-bit integer');
    }

    for (var i = numBits - 1; i >= 0; i--) {
      // Test bit
      final bit = (data >> i & 1) != 0;
      if (bit) {
        // Set bit in current byte
        _currentByte.setUint8(
            0, _currentByte.getUint8(0) | (1 << _currentBitIndex));
      }

      // Decrease current bit index
      --_currentBitIndex;

      // Check if the current byte can be written
      if (_currentBitIndex < 0) {
        _writeCurrentByte();
      }
    }
  }

  /// Writes a sequence of bytes to the stream
  void writeBytes(typed.Uint8Buffer bytes) {
    // Check if anything to do at all
    if (bytes == null) {
      return;
    }

    // Are there bits left to write in buffer?
    if (_currentBitIndex < 7) {
      for (var i = 0; i < bytes.length; i++) {
        write(bytes[i], 8);
      }
    } else {
      // if bit buffer is empty, call can be delegated
      // to byte stream to increase
      _buffer.addAll(bytes);
    }
  }

  /// Writes one byte to the stream.
  void writeByte(int b) {
    final buff = typed.Uint8Buffer()..add(b);
    writeBytes(buff);
  }

  /// Returns a byte array containing the sequence of bits written
  typed.Uint8Buffer toByteArray() {
    _writeCurrentByte();
    return _buffer;
  }

  void _writeCurrentByte() {
    if (_currentBitIndex < 7) {
      _buffer.add(_currentByte.getUint8(0));
      _currentByte.setUint8(0, 0);
      _currentBitIndex = 7;
    }
  }
}
