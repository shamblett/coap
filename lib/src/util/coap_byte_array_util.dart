// ignore_for_file: avoid_classes_with_only_static_members

/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/05/2017
 * Copyright :  S.Hamblett
 */

import 'package:hex/hex.dart';
import 'package:typed_data/typed_data.dart';

/// Utility methods for bytes array.
class CoapByteArrayUtil {
  /// Returns a hex string representation of the given bytes array.
  static String toHexString(final Uint8Buffer data) =>
      HEX.encode(data.toList());

  /// Parses a bytes array from its hex string representation.
  static Uint8Buffer fromHexString(final String data) =>
      Uint8Buffer()..addAll(HEX.decode(data));
}
