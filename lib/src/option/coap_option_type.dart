// ignore_for_file: no-magic-number

/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

import 'dart:collection';

import 'package:typed_data/typed_buffers.dart';

import 'coap_block_option.dart';
import 'empty_option.dart';
import 'integer_option.dart';
import 'opaque_option.dart';
import 'option.dart';
import 'oscore_option.dart';
import 'string_option.dart';

/// Base class for [Exception]s that are thrown when an unknown CoapOption
/// number is encountered during the parsing of a CoapMessage.
abstract class UnknownOptionException implements Exception {
  /// The unknown option number that was encountered.
  final int optionNumber;

  final String errorMessage;

  /// Constructor.
  UnknownOptionException(this.optionNumber, this.errorMessage);

  @override
  String toString() => 'UnknownOptionException: $errorMessage';
}

/// [Exception] that is thrown when an unknown elective CoapOption number is
/// encountered during the parsing of a CoapMessage.
class UnknownElectiveOptionException extends UnknownOptionException {
  /// Constructor.
  UnknownElectiveOptionException(super.optionNumber, super.errorMessage);
}

/// [Exception] that is thrown when an unknown critical CoapOption number is
/// encountered during the parsing of a CoapMessage.
class UnknownCriticalOptionException extends UnknownOptionException {
  /// Constructor.
  UnknownCriticalOptionException(super.optionNumber, super.errorMessage);
}

/// CoAP option types as defined in
/// RFC 7252, Section 12.2 and other CoAP extensions.
enum OptionType implements Comparable<OptionType> {
  /// C, opaque, 0-8 B, -
  ifMatch(
    1,
    'If-Match',
    OptionFormat.opaque,
    minLength: 0,
    maxLength: 8,
    repeatable: true,
  ),

  /// C, String, 1-270 B, ""
  uriHost(3, 'Uri-Host', OptionFormat.string, minLength: 1, maxLength: 255),

  /// E, sequence of bytes, 1-4 B, -
  eTag(
    4,
    'ETag',
    OptionFormat.opaque,
    minLength: 1,
    maxLength: 8,
    repeatable: true,
  ),

  ifNoneMatch(
    5,
    'If-None-Match',
    OptionFormat.empty,
    minLength: 0,
    maxLength: 0,
  ),

  /// E, Duration, 1 B, 0
  observe(6, 'Observe', OptionFormat.integer, minLength: 0, maxLength: 3),

  /// C, uint, 0-2 B
  uriPort(7, 'Uri-Port', OptionFormat.integer, minLength: 0, maxLength: 2),

  /// E, String, 1-270 B, -
  locationPath(
    8,
    'Location-Path',
    OptionFormat.string,
    minLength: 0,
    maxLength: 255,
    repeatable: true,
  ),

  /// C, String, 0-255 B, -
  ///
  /// Defined in [RFC 8613](https://datatracker.ietf.org/doc/html/rfc8613).
  oscore(9, 'OSCORE', OptionFormat.oscore, minLength: 0, maxLength: 255),

  /// C, String, 1-270 B, ""
  uriPath(
    11,
    'Uri-Path',
    OptionFormat.string,
    minLength: 0,
    maxLength: 255,
    repeatable: true,
  ),

  /// C, 8-bit uint, 1 B, 0 (text/plain)
  contentFormat(
    12,
    'Content-Format',
    OptionFormat.integer,
    minLength: 0,
    maxLength: 2,
  ),

  /// E, variable length, 1--4 B, 60 Seconds
  maxAge(
    14,
    'Max-Age',
    OptionFormat.integer,
    minLength: 0,
    maxLength: 4,
    defaultValue: 60,
  ),

  /// C, String, 1-270 B, ""
  uriQuery(
    15,
    'Uri-Query',
    OptionFormat.string,
    minLength: 0,
    maxLength: 255,
    repeatable: true,
  ),

  /// E, uint, 1 B, 16
  ///
  /// Defined in [RFC 8768](https://datatracker.ietf.org/doc/html/rfc8768).
  hopLimit(16, 'Hop-Limit', OptionFormat.integer, minLength: 1, maxLength: 1),

  /// C, Sequence of Bytes, 1-n B, -
  accept(17, 'Accept', OptionFormat.integer, minLength: 0, maxLength: 2),

  /// C, uint, 0-3 B, -
  ///
  /// Defined in [RFC 9177](https://datatracker.ietf.org/doc/html/rfc9177).
  qBlock1(19, 'Q-Block1', OptionFormat.integer, minLength: 0, maxLength: 3),

  /// C, empty, 0 B, -
  ///
  /// Defined in [draft-ietf-core-oscore-edhoc-02].
  ///
  /// Note: The registration of this option is only temporary at the moment
  /// and might be removed by IANA if draft-ietf-core-oscore-edhoc does not
  /// become an RFC.
  ///
  /// [draft-ietf-core-oscore-edhoc-04]: https://datatracker.ietf.org/doc/html/draft-ietf-core-oscore-edhoc-04#section-3.1
  edhoc(21, 'EDHOC', OptionFormat.empty, minLength: 0, maxLength: 0),

  /// E, String, 1-270 B, -
  locationQuery(
    20,
    'Location-Query',
    OptionFormat.string,
    minLength: 0,
    maxLength: 255,
    repeatable: true,
  ),
  block2(23, 'Block2', OptionFormat.integer, minLength: 0, maxLength: 3),
  block1(27, 'Block1', OptionFormat.integer, minLength: 0, maxLength: 3),
  size2(28, 'Size2', OptionFormat.integer, minLength: 0, maxLength: 4),

  /// C, uint, 0-3 B, -
  ///
  /// Defined in [RFC 9177](https://datatracker.ietf.org/doc/html/rfc9177).
  qBlock2(
    31,
    'Q-Block2',
    OptionFormat.integer,
    minLength: 0,
    maxLength: 3,
    repeatable: true,
  ),

  /// C, String, 1-270 B, "coap"
  proxyUri(35, 'Proxy-Uri', OptionFormat.string, minLength: 1, maxLength: 1034),

  proxyScheme(
    39,
    'Proxy-Scheme',
    OptionFormat.string,
    minLength: 1,
    maxLength: 255,
  ),
  size1(60, 'Size1', OptionFormat.integer, minLength: 0, maxLength: 4),

  /// E, opaque, 1-40 B, -
  ///
  /// Defined in [RFC 9175](https://datatracker.ietf.org/doc/html/rfc9175).
  echo(252, 'Echo', OptionFormat.opaque, minLength: 1, maxLength: 40),

  /// E, uint, 0-1 B, 0
  ///
  /// Defined in [RFC 7967](https://datatracker.ietf.org/doc/html/rfc7967),
  /// updated by [RFC 8613](https://datatracker.ietf.org/doc/html/rfc8613).
  noResponse(
    258,
    'No-Response',
    OptionFormat.integer,
    minLength: 0,
    maxLength: 1,
  ),

  /// E, opaque, 0-8 B, -
  ///
  /// Defined in [RFC 9175](https://datatracker.ietf.org/doc/html/rfc9175).
  requestTag(
    292,
    'Request-Tag',
    OptionFormat.opaque,
    minLength: 1,
    maxLength: 40,
  ),

  /// C, uint, 2 B, -
  ///
  /// Defined in the [OCF Core Specification v1.3.0 Part 1], page 128.
  ///
  /// [OCF Core Specification v1.3.0]: https://openconnectivity.org/specs/OCF_Core_Specification_v1.3.0.pdf
  ocfAcceptContentFormatVersion(
    2049,
    'OCF-Accept-Content-Format-Version',
    OptionFormat.integer,
    minLength: 2,
    maxLength: 2,
  ),

  /// C, uint, 2 B, -
  ///
  /// Defined in the [OCF Core Specification v1.3.0 Part 1], page 128.
  ///
  /// [OCF Core Specification v1.3.0]: https://openconnectivity.org/specs/OCF_Core_Specification_v1.3.0.pdf
  ocfContentFormatVersion(
    2053,
    'OCF-Content-Format-Version',
    OptionFormat.integer,
    minLength: 2,
    maxLength: 2,
  );

  const OptionType(
    this.optionNumber,
    this.optionName,
    this.optionFormat, {
    required this.minLength,
    required this.maxLength,
    this.defaultValue,
    this.repeatable = false,
  });

  /// The number of this option.
  final int optionNumber;

  /// The name of this option.
  final String optionName;

  /// The [OptionFormat] of this option (integer, string, opaque, or unknown).
  final OptionFormat<Object?> optionFormat;

  final bool repeatable;

  /// The minimum length of this [OptionType] in bytes.
  final int minLength;

  /// The maximum length of this [OptionType] in bytes.
  final int maxLength;

  final Object? defaultValue;

  static final _registry = HashMap.fromEntries(
    values.map((final value) => MapEntry(value.optionNumber, value)),
  );

  /// Creates a new [OptionType] object from a numeric [type].
  static OptionType fromTypeNumber(final int type) {
    final optionType = _registry[type];

    if (optionType != null) {
      return optionType;
    }

    final errorMessage = 'Uncountered an unknown option number $type';

    if (type.isOdd) {
      throw UnknownCriticalOptionException(type, errorMessage);
    } else {
      throw UnknownElectiveOptionException(type, errorMessage);
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

  /// Checks whether this option is *not* part of the cache key.
  ///
  /// See [Section 5.4.2] and [Section 5.4.6] of RFC 7252 for more information.
  ///
  /// [Section 5.4.2]: https://www.rfc-editor.org/rfc/rfc7252#section-5.4.2
  /// [Section 5.4.6]: https://www.rfc-editor.org/rfc/rfc7252#section-5.4.6
  bool get isNoCacheKey => (optionNumber & 0x1e) == 0x1c;

  /// Checks whether this option is part of the cache key.
  ///
  /// See the [isNoCacheKey] getter for more information.
  bool get isCacheKey => !isNoCacheKey;

  Option<Object?> parse(final Uint8Buffer bytes) {
    switch (this) {
      case OptionType.ifMatch:
        return IfMatchOption(bytes);
      case OptionType.uriHost:
        return UriHostOption.parse(bytes);
      case OptionType.eTag:
        return ETagOption(bytes);
      case OptionType.ifNoneMatch:
        return IfNoneMatchOption();
      case OptionType.observe:
        return ObserveOption.parse(bytes);
      case OptionType.uriPort:
        return UriPortOption.parse(bytes);
      case OptionType.locationPath:
        return LocationPathOption.parse(bytes);
      case OptionType.oscore:
        return OscoreOption.parse(bytes);
      case OptionType.uriPath:
        return UriPathOption.parse(bytes);
      case OptionType.contentFormat:
        return ContentFormatOption.parse(bytes);
      case OptionType.maxAge:
        return MaxAgeOption.parse(bytes);
      case OptionType.uriQuery:
        return UriQueryOption.parse(bytes);
      case OptionType.hopLimit:
        return HopLimitOption.parse(bytes);
      case OptionType.accept:
        return AcceptOption.parse(bytes);
      case OptionType.qBlock1:
        return QBlock1Option.parse(bytes);
      case OptionType.edhoc:
        return EdhocOption();
      case OptionType.locationQuery:
        return LocationQueryOption.parse(bytes);
      case OptionType.block2:
        return Block2Option.parse(bytes);
      case OptionType.block1:
        return Block1Option.parse(bytes);
      case OptionType.size2:
        return Size2Option.parse(bytes);
      case OptionType.qBlock2:
        return QBlock2Option.parse(bytes);
      case OptionType.proxyUri:
        return ProxyUriOption.parse(bytes);
      case OptionType.proxyScheme:
        return ProxySchemeOption.parse(bytes);
      case OptionType.size1:
        return Size1Option.parse(bytes);
      case OptionType.echo:
        return EchoOption(bytes);
      case OptionType.noResponse:
        return NoResponseOption.parse(bytes);
      case OptionType.requestTag:
        return RequestTagOption(bytes);
      case OptionType.ocfAcceptContentFormatVersion:
        return OcfAcceptContentFormatVersion.parse(bytes);
      case OptionType.ocfContentFormatVersion:
        return OcfContentFormatVersion.parse(bytes);
    }
  }
}

/// CoAP option formats.
enum OptionFormat<T> {
  integer<int>(),
  string<String>(),
  opaque<Uint8Buffer>(),
  oscore<OscoreOptionValue>(),
  empty<void>(),
}
