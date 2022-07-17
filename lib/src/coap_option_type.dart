/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

import 'dart:collection';

/// Base class for [Exception]s that are thrown when an unknown CoapOption
/// number is encountered during the parsing of a CoapMessage.
abstract class UnknownOptionException implements Exception {
  /// The unknown option number that was encountered.
  int optionNumber;

  /// Constructor.
  UnknownOptionException(this.optionNumber);

  @override
  String toString() =>
      '$runtimeType:  Encountered unknown option number $optionNumber';
}

/// [Exception] that is thrown when an unknown elective CoapOption number is
/// encountered during the parsing of a CoapMessage.
class UnknownElectiveOptionException extends UnknownOptionException {
  /// Constructor.
  UnknownElectiveOptionException(super.optionNumber);
}

/// [Exception] that is thrown when an unknown critical CoapOption number is
/// encountered during the parsing of a CoapMessage.
class UnknownCriticalOptionException extends UnknownOptionException {
  /// Constructor.
  UnknownCriticalOptionException(super.optionNumber);
}

/// CoAP option types as defined in
/// RFC 7252, Section 12.2 and other CoAP extensions.
enum OptionType implements Comparable<OptionType> {
  /// C, opaque, 0-8 B, -
  ifMatch(1, 'If-Match', OptionFormat.opaque),

  /// C, String, 1-270 B, ""
  uriHost(3, 'Uri-Host', OptionFormat.string),

  /// E, sequence of bytes, 1-4 B, -
  eTag(4, 'ETag', OptionFormat.opaque),

  ifNoneMatch(5, 'If-None-Match', OptionFormat.empty),

  /// E, Duration, 1 B, 0
  observe(6, 'Observe', OptionFormat.integer),

  /// C, uint, 0-2 B
  uriPort(7, 'Uri-Port', OptionFormat.integer),

  /// E, String, 1-270 B, -
  locationPath(8, 'Location-Path', OptionFormat.string),

  /// C, String, 1-270 B, ""
  uriPath(11, 'Uri-Path', OptionFormat.string),

  /// C, 8-bit uint, 1 B, 0 (text/plain)
  contentFormat(12, 'Content-Format', OptionFormat.integer),

  /// E, variable length, 1--4 B, 60 Seconds
  maxAge(14, 'Max-Age', OptionFormat.integer),

  /// C, String, 1-270 B, ""
  uriQuery(15, 'Uri-Query', OptionFormat.string),

  /// C, Sequence of Bytes, 1-n B, -
  accept(17, 'Accept', OptionFormat.integer),

  /// E, String, 1-270 B, -
  locationQuery(20, 'Location-Query', OptionFormat.string),
  block2(23, 'Block2', OptionFormat.integer),
  block1(27, 'Block1', OptionFormat.integer),
  size2(28, 'Size2', OptionFormat.integer),

  /// C, String, 1-270 B, "coap"
  proxyUri(35, 'Proxy-Uri', OptionFormat.string),

  proxyScheme(39, 'Proxy-Scheme', OptionFormat.string),
  size1(60, 'Size1', OptionFormat.integer);

  /// The number of this option.
  final int optionNumber;

  /// The name of this option.
  final String optionName;

  /// The [OptionFormat] of this option (integer, string, opaque, or unknown).
  final OptionFormat optionFormat;
  const OptionType(this.optionNumber, this.optionName, this.optionFormat);

  static final _registry = HashMap.fromEntries(
    values.map((final value) => MapEntry(value.optionNumber, value)),
  );

  /// Creates a new [OptionType] object from a numeric [type].
  static OptionType fromTypeNumber(final int type) {
    final optionType = _registry[type];

    if (optionType != null) {
      return optionType;
    }

    if (type.isOdd) {
      throw UnknownCriticalOptionException(type);
    } else {
      throw UnknownElectiveOptionException(type);
    }
  }

  @override
  int compareTo(final OptionType other) {
    if (optionNumber == other.optionNumber) {
      return 0;
    }

    if (optionNumber < other.optionNumber) {
      return -1;
    }

    return 1;
  }

  /// Checks whether an option is critical.
  bool get isCritical => optionNumber.isOdd;

  /// Checks whether an option is elective.
  bool get isElective => optionNumber.isEven;

  /// Checks whether an option is unsafe.
  bool get isUnsafe => (optionNumber & 2) > 0;

  /// Checks whether an option is safe.
  bool get isSafe => !isUnsafe;
}

/// CoAP option formats.
enum OptionFormat { integer, string, opaque, empty, unknown }
