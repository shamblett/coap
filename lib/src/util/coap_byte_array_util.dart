/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/05/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Utility methods for bytes array.
class CoapByteArrayUtil {
  /// Returns a hex string representation of the given bytes array.
  static String toHexString(typed.Uint8Buffer data) =>
      hex.HEX.encode(data.toList());

  /// Parses a bytes array from its hex string representation.
  static typed.Uint8Buffer fromHexString(String data) {
    final ret = typed.Uint8Buffer();
    ret.addAll(hex.HEX.decode(data));
    return ret;
  }
}
