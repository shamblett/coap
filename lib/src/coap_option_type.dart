/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

// Option numbers
const _ifMatch = 1;
const _uriHost = 3;
const _eTag = 4;
const _ifNoneMatch = 5;
const _observe = 6;
const _uriPort = 7;
const _locationPath = 8;
const _uriPath = 11;
const _contentFormat = 12;
const _maxAge = 14;
const _uriQuery = 15;
const _accept = 17;
const _locationQuery = 20;
const _block2 = 23;
const _block1 = 27;
const _size2 = 28;
const _proxyUri = 35;
const _proxyScheme = 39;
const _size1 = 60;

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
  ifMatch(_ifMatch, 'If-Match', OptionFormat.opaque),

  /// C, String, 1-270 B, ""
  uriHost(_uriHost, 'Uri-Host', OptionFormat.string),

  /// E, sequence of bytes, 1-4 B, -
  eTag(_eTag, 'ETag', OptionFormat.opaque),

  ifNoneMatch(_ifNoneMatch, 'If-None-Match', OptionFormat.empty),

  /// E, Duration, 1 B, 0
  observe(_observe, 'Observe', OptionFormat.integer),

  /// C, uint, 0-2 B
  uriPort(_uriPort, 'Uri-Port', OptionFormat.integer),

  /// E, String, 1-270 B, -
  locationPath(_locationPath, 'Location-Path', OptionFormat.string),

  /// C, String, 1-270 B, ""
  uriPath(_uriPath, 'Uri-Path', OptionFormat.string),

  /// C, 8-bit uint, 1 B, 0 (text/plain)
  contentFormat(_contentFormat, 'Content-Format', OptionFormat.integer),

  /// E, variable length, 1--4 B, 60 Seconds
  maxAge(_maxAge, 'Max-Age', OptionFormat.integer),

  /// C, String, 1-270 B, ""
  uriQuery(_uriQuery, 'Uri-Query', OptionFormat.string),

  /// C, Sequence of Bytes, 1-n B, -
  accept(_accept, 'Accept', OptionFormat.integer),

  /// E, String, 1-270 B, -
  locationQuery(_locationQuery, 'Location-Query', OptionFormat.string),
  block2(_block2, 'Block2', OptionFormat.integer),
  block1(_block1, 'Block1', OptionFormat.integer),
  size2(_size2, 'Size2', OptionFormat.integer),

  /// C, String, 1-270 B, "coap"
  proxyUri(_proxyUri, 'Proxy-Uri', OptionFormat.string),

  proxyScheme(_proxyScheme, 'Proxy-Scheme', OptionFormat.string),
  size1(_size1, 'Size1', OptionFormat.integer);

  /// The number of this option.
  final int optionNumber;

  /// The name of this option.
  final String name;

  /// The [OptionFormat] of this option (integer, string, opaque, or unknown).
  final OptionFormat optionFormat;
  const OptionType(this.optionNumber, this.name, this.optionFormat);

  /// Creates a new [OptionType] object from a numeric [type].
  static OptionType fromTypeNumber(final int type) {
    switch (type) {
      case _ifMatch:
        return OptionType.ifMatch;
      case _uriHost:
        return OptionType.uriHost;
      case _eTag:
        return OptionType.eTag;
      case _ifNoneMatch:
        return OptionType.ifNoneMatch;
      case _observe:
        return OptionType.observe;
      case _uriPort:
        return OptionType.uriPort;
      case _locationPath:
        return OptionType.locationPath;
      case _uriPath:
        return OptionType.uriPath;
      case _contentFormat:
        return OptionType.contentFormat;
      case _maxAge:
        return OptionType.maxAge;
      case _uriQuery:
        return OptionType.uriQuery;
      case _accept:
        return OptionType.accept;
      case _locationQuery:
        return OptionType.locationQuery;
      case _block2:
        return OptionType.block2;
      case _block1:
        return OptionType.block1;
      case _size2:
        return OptionType.size2;
      case _proxyUri:
        return OptionType.proxyUri;
      case _proxyScheme:
        return OptionType.proxyScheme;
      case _size1:
        return OptionType.size1;
      default:
        if (type.isOdd) {
          throw UnknownCriticalOptionException(type);
        } else {
          throw UnknownElectiveOptionException(type);
        }
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
