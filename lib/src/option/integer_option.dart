// ignore_for_file: avoid_redundant_argument_values

import 'dart:typed_data';

import 'package:typed_data/typed_data.dart';

import '../coap_media_type.dart';
import 'coap_option_type.dart';
import 'option.dart';

/// The byte order used when converting to and from binary integer option
/// values.
///
/// As originally specified in [RFC 1700], a big-endian order is used for the
/// Internet protocol suite.
///
/// [RFC 1700]: https://www.rfc-editor.org/rfc/rfc1700
const _networkByteOrder = Endian.big;

/// Option format for non-negative integer values represented in network byte
/// order.
///
/// See [RFC 7252, section 3.2] for more information.
///
/// [RFC 7252, section 3.2]: https://www.rfc-editor.org/rfc/rfc7252#section-3.2
abstract class IntegerOption extends Option<int> {
  /// Create an [IntegerOption] of a specified [type], encoding the given
  /// [value].
  ///
  /// The [value] will be encoded using network byte order.
  IntegerOption(this.type, this.value) : byteValue = _bytesFromValue(value);

  /// Create an [IntegerOption] of a specified [type], parsing the given
  /// encoded [byteValue].
  ///
  /// The [byteValue] needs to be encoded in network byte order.
  IntegerOption.parse(this.type, this.byteValue)
    : value = _valueFromBytes(byteValue);

  @override
  final Uint8Buffer byteValue;

  @override
  final optionFormat = OptionFormat.integer;

  @override
  final OptionType type;
  @override
  final int value;

  static int _valueFromBytes(final Uint8Buffer byteValue) {
    switch (byteValue.length) {
      case 0:
        return 0;
      case 1:
        return byteValue[0];
      case 2:
        return ByteData.view(byteValue.buffer).getUint16(0, _networkByteOrder);
      case 3:
      case 4:
        final paddedBytes = Uint8List(4)..setAll(0, byteValue);
        return ByteData.view(
          paddedBytes.buffer,
        ).getUint32(0, _networkByteOrder);
      default:
        final paddedBytes = Uint8List(8)..setAll(0, byteValue);
        return ByteData.view(
          paddedBytes.buffer,
        ).getUint64(0, _networkByteOrder);
    }
  }

  static Uint8Buffer _bytesFromValue(final int value) {
    final ByteData data;
    if (value < 0 || value >= (1 << 32)) {
      data = ByteData(8)..setUint64(0, value, _networkByteOrder);
    } else if (value < (1 << 8)) {
      data = ByteData(1)..setUint8(0, value);
    } else if (value < (1 << 16)) {
      data = ByteData(2)..setUint16(0, value, _networkByteOrder);
    } else {
      data = ByteData(4)..setUint32(0, value, _networkByteOrder);
    }

    return _trimData(data);
  }

  /// Trims [byteData] in accordance with [RFC 7252, section 3.2]:
  ///
  /// "A sender SHOULD represent the integer with as few bytes as possible,
  /// i.e., without leading zero bytes" (leading big endian being trailing).
  ///
  /// Note that a value like 256 *has* to be represented with a leading zero
  /// byte, as otherwise the option value will be interpreted as 1 in this case.
  ///
  /// [RFC 7252, section 3.2]: https://www.rfc-editor.org/rfc/rfc7252#section-3.2
  static Uint8Buffer _trimData(final ByteData byteData) {
    final buffer = Uint8Buffer()..addAll(byteData.buffer.asUint8List());
    while (_needsLeadingByteRemoval(buffer)) {
      buffer.removeLast();
    }

    return buffer;
  }

  /// Indicates if the leading byte of a [buffer] should be removed.
  static bool _needsLeadingByteRemoval(final Uint8Buffer buffer) =>
      _secondLastElementIsZeroOrEmpty(buffer) && _lastElementIsZero(buffer);

  /// Indicates if the last element of a [buffer] is zero.
  ///
  /// Returns `false`  if this [Uint8Buffer] is empty.
  static bool _lastElementIsZero(final Uint8Buffer buffer) {
    if (buffer.isEmpty) {
      return false;
    }

    return buffer.last == 0;
  }

  /// Indicates if the second last element of a [buffer] is zero or not present.
  ///
  /// Returns `true`  if the length of this [Uint8Buffer] is less than 2.
  static bool _secondLastElementIsZeroOrEmpty(final Uint8Buffer buffer) {
    if (buffer.length < 2) {
      return true;
    }

    return buffer.elementAt(buffer.length - 2) == 0;
  }

  @override
  String get valueString =>
      (type == OptionType.accept || type == OptionType.contentFormat)
          ? CoapMediaType.fromIntValue(value).toString()
          : value.toString();

  bool get isDefault => value == type.defaultValue;
}

class ContentFormatOption extends IntegerOption with OscoreOptionClassE {
  ContentFormatOption(final int value) : super(OptionType.contentFormat, value);

  ContentFormatOption.parse(final Uint8Buffer bytes)
    : super.parse(OptionType.contentFormat, bytes);
}

/// Models the legal values for including the [ObserveOption] an a CoAP GET
/// request.
///
/// See [RFC 7641, section 2] for more information.
///
///
/// [RFC 7641, section 2]: https://www.rfc-editor.org/rfc/rfc7641#section-2
enum ObserveRegistration {
  register(0),
  deregister(1);

  /// Constructor
  const ObserveRegistration(this.value);

  /// The numeric value associated with this [ObserveRegistration].
  final int value;

  static final _registry = Map.fromEntries(
    values.map((final value) => MapEntry(value.value, value)),
  );

  /// Parses a numeric [value] and returns an [ObserveRegistration] enum value
  /// if it matches.
  static ObserveRegistration? parse(final int value) => _registry[value];
}

/// Option for observing resources with CoAP.
///
/// Specified in [RFC 7641, section 2].
///
///
/// [RFC 7641, section 2]: https://www.rfc-editor.org/rfc/rfc7641#section-2
class ObserveOption extends IntegerOption
    with OscoreOptionClassE, OscoreOptionClassU {
  ObserveOption(final int value) : super(OptionType.observe, value);

  ObserveOption.parse(final Uint8Buffer bytes)
    : super.parse(OptionType.observe, bytes);

  /// Creates a [ObserveOption] that starts an observation process when included
  /// in a GET request.
  ObserveOption.register() : this(ObserveRegistration.register.value);

  /// Creates a [ObserveOption] that terminates an observation process when
  /// included in a GET request.
  ObserveOption.deregister() : this(ObserveRegistration.deregister.value);

  /// Returns the [ObserveRegistration] value this option represents if its
  /// value can be parsed as either a registration (= 0) or a deregistration.
  ObserveRegistration? get registrationValue =>
      ObserveRegistration.parse(value);
}

class UriPortOption extends IntegerOption with OscoreOptionClassU {
  UriPortOption(final int value) : super(OptionType.uriPort, value);

  UriPortOption.parse(final Uint8Buffer bytes)
    : super.parse(OptionType.uriPort, bytes);
}

class MaxAgeOption extends IntegerOption
    with OscoreOptionClassE, OscoreOptionClassU {
  MaxAgeOption(final int value) : super(OptionType.maxAge, value);

  MaxAgeOption.parse(final Uint8Buffer bytes)
    : super.parse(OptionType.maxAge, bytes);
}

class HopLimitOption extends IntegerOption with OscoreOptionClassE {
  HopLimitOption(final int value) : super(OptionType.hopLimit, value);

  HopLimitOption.parse(final Uint8Buffer bytes)
    : super.parse(OptionType.hopLimit, bytes);
}

class AcceptOption extends IntegerOption with OscoreOptionClassE {
  AcceptOption(final int value) : super(OptionType.accept, value);

  AcceptOption.parse(final Uint8Buffer bytes)
    : super.parse(OptionType.accept, bytes);
}

class Size2Option extends IntegerOption
    with OscoreOptionClassE, OscoreOptionClassU {
  Size2Option(final int value) : super(OptionType.size2, value);

  Size2Option.parse(final Uint8Buffer bytes)
    : super.parse(OptionType.size2, bytes);
}

class Size1Option extends IntegerOption
    with OscoreOptionClassE, OscoreOptionClassU {
  Size1Option(final int value) : super(OptionType.size1, value);

  Size1Option.parse(final Uint8Buffer bytes)
    : super.parse(OptionType.size1, bytes);
}

class NoResponseOption extends IntegerOption {
  NoResponseOption(final int value) : super(OptionType.noResponse, value);

  NoResponseOption.parse(final Uint8Buffer bytes)
    : super.parse(OptionType.noResponse, bytes);
}

/// Base class for the OCF options [OcfAcceptContentFormatVersion] and
/// [OcfContentFormatVersion].
abstract class OcfVersionOption extends IntegerOption with OscoreOptionClassE {
  OcfVersionOption(super.type, super.value);

  OcfVersionOption.parse(super.type, super.bytes) : super.parse();

  /// Creates a new OCF version option of a specified [type] composed of a
  /// [majorVersion], a [minorVersion], and a [subVersion].
  OcfVersionOption.fromVersion(
    final OptionType type,
    final int majorVersion,
    final int minorVersion,
    final int subVersion,
  ) : super(type, _versionToValue(majorVersion, minorVersion, subVersion));

  static int _versionToValue(
    final int majorVersion,
    final int minorVersion,
    final int subVersion,
  ) =>
      (majorVersion << _majorBitShift) +
      (minorVersion << _minorBitShift) +
      subVersion;

  static int _maskBits(final int maskLength) => (1 << maskLength) - 1;

  static const _majorBitShift = 11;

  static const _minorBitShift = 6;

  /// The major version represented by the option [value].
  ///
  /// Represented by the five most significant bits.
  int get majorVersion => (value >> _majorBitShift) & _maskBits(5);

  /// The minor version represented by the option [value].
  ///
  /// Represented by bits 6 to 10.
  int get minorVersion => (value >> _minorBitShift) & _maskBits(5);

  /// The sub version represented by the option [value].
  ///
  /// Represented by the six least significant bits.
  int get subVersion => value & _maskBits(6);

  @override
  String get valueString => '$majorVersion.$minorVersion.$subVersion';
}

class OcfAcceptContentFormatVersion extends OcfVersionOption {
  OcfAcceptContentFormatVersion(final int value)
    : super(OptionType.ocfAcceptContentFormatVersion, value);

  OcfAcceptContentFormatVersion.parse(final Uint8Buffer bytes)
    : super.parse(OptionType.ocfAcceptContentFormatVersion, bytes);

  /// Creates a new [OcfAcceptContentFormatVersion] composed of a
  /// [majorVersion], a [minorVersion], and a [subVersion].
  OcfAcceptContentFormatVersion.fromVersion(
    final int majorVersion,
    final int minorVersion,
    final int subVersion,
  ) : super.fromVersion(
        OptionType.ocfAcceptContentFormatVersion,
        majorVersion,
        minorVersion,
        subVersion,
      );
}

class OcfContentFormatVersion extends OcfVersionOption {
  OcfContentFormatVersion(final int value)
    : super(OptionType.ocfContentFormatVersion, value);

  OcfContentFormatVersion.parse(final Uint8Buffer bytes)
    : super.parse(OptionType.ocfContentFormatVersion, bytes);

  /// Creates a new [OcfContentFormatVersion] composed of a [majorVersion], a
  /// [minorVersion], and a [subVersion].
  OcfContentFormatVersion.fromVersion(
    final int majorVersion,
    final int minorVersion,
    final int subVersion,
  ) : super.fromVersion(
        OptionType.ocfContentFormatVersion,
        majorVersion,
        minorVersion,
        subVersion,
      );
}
