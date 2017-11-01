/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/05/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Utility methods for bytes array.
class CoapByteArrayUtils {
  /// Hashing constants
  static const int p = 16777619;
  static const int hashSeed = 2166136261;

  /// Returns a hex string representation of the given bytes array.
  static String toHexString(typed.Uint8Buffer data) {
    return hex.HEX.encode(data.toList());
  }

  /// Parses a bytes array from its hex string representation.
  static typed.Uint8Buffer fromHexString(String data) {
    final typed.Uint8Buffer ret = new typed.Uint8Buffer();
    ret.addAll(hex.HEX.decode(data));
    return ret;
  }

  /// Checks if the two bytes arrays are equal.
  static bool equals(typed.Uint8Buffer bytes1, typed.Uint8Buffer bytes2) {
    return (bytes1 == bytes2);
  }

  /// Computes the hash of the given bytes array.
  static int computeHash(typed.Uint8Buffer data) {
    int hash = hashSeed;

    for (int i = 0; i < data.length; i++) {
      hash = (hash ^ data[i]) * p;
    }
    hash += hash << 13;
    hash ^= hash >> 7;
    hash += hash << 3;
    hash ^= hash >> 17;
    hash += hash << 5;
    return hash;
  }
}
