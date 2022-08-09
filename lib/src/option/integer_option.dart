import 'dart:typed_data';

import 'package:typed_data/typed_data.dart';

import '../coap_media_type.dart';
import 'coap_option_type.dart';
import 'option.dart';

abstract class IntegerOption extends Option<int> {
  IntegerOption(this.type, this.value) : byteValue = _bytesFromValue(value);

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
    // TODO(JKRhb): The handling of endianness should be revisited here.
    switch (byteValue.length) {
      case 0:
        return 0;
      case 1:
        return byteValue[0];
      case 2:
        return ByteData.view(byteValue.buffer).getUint16(0, Endian.host);
      case 3:
      case 4:
        final paddedBytes = Uint8List(4)..setAll(0, byteValue);
        return ByteData.view(paddedBytes.buffer).getUint32(0, Endian.host);
      default:
        final paddedBytes = Uint8List(8)..setAll(0, byteValue);
        return ByteData.view(paddedBytes.buffer).getUint64(0, Endian.host);
    }
  }

  static Uint8Buffer _bytesFromValue(final int value) {
    // TODO(JKRhb): The handling of endianness should be revisited here.
    ByteData data;
    if (value < 0 || value >= (1 << 32)) {
      data = ByteData(8)..setUint64(0, value);
    } else if (value < (1 << 8)) {
      data = ByteData(1)..setUint8(0, value);
    } else if (value < (1 << 16)) {
      data = ByteData(2)..setUint16(0, value, Endian.host);
    } else {
      data = ByteData(4)..setUint32(0, value, Endian.host);
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

class ContentFormatOption extends IntegerOption implements OscoreOptionClassE {
  ContentFormatOption(final int value) : super(OptionType.contentFormat, value);

  ContentFormatOption.parse(final Uint8Buffer bytes)
      : super.parse(OptionType.contentFormat, bytes);
}

/// Option for observing resources with CoAP.
///
/// Specified in [RFC 7641, section 2].
///
///
/// [RFC 7641, section 2]: https://www.rfc-editor.org/rfc/rfc7641#section-2
class ObserveOption extends IntegerOption
    implements OscoreOptionClassE, OscoreOptionClassU {
  ObserveOption(final int value) : super(OptionType.observe, value);

  ObserveOption.parse(final Uint8Buffer bytes)
      : super.parse(OptionType.observe, bytes);
}

class UriPortOption extends IntegerOption implements OscoreOptionClassU {
  UriPortOption(final int value) : super(OptionType.uriPort, value);

  UriPortOption.parse(final Uint8Buffer bytes)
      : super.parse(OptionType.uriPort, bytes);
}

class MaxAgeOption extends IntegerOption
    implements OscoreOptionClassE, OscoreOptionClassU {
  MaxAgeOption(final int value) : super(OptionType.maxAge, value);

  MaxAgeOption.parse(final Uint8Buffer bytes)
      : super.parse(OptionType.maxAge, bytes);
}

// TODO(JKRhb): Is this really a class U option?
class HopLimitOption extends IntegerOption implements OscoreOptionClassU {
  HopLimitOption(final int value) : super(OptionType.hopLimit, value);

  HopLimitOption.parse(final Uint8Buffer bytes)
      : super.parse(OptionType.hopLimit, bytes);
}

class AcceptOption extends IntegerOption implements OscoreOptionClassE {
  AcceptOption(final int value) : super(OptionType.accept, value);

  AcceptOption.parse(final Uint8Buffer bytes)
      : super.parse(OptionType.accept, bytes);
}

class Size2Option extends IntegerOption
    implements OscoreOptionClassE, OscoreOptionClassU {
  Size2Option(final int value) : super(OptionType.size2, value);

  Size2Option.parse(final Uint8Buffer bytes)
      : super.parse(OptionType.size2, bytes);
}

class Size1Option extends IntegerOption
    implements OscoreOptionClassE, OscoreOptionClassU {
  Size1Option(final int value) : super(OptionType.size1, value);

  Size1Option.parse(final Uint8Buffer bytes)
      : super.parse(OptionType.size1, bytes);
}

class NoResponseOption extends IntegerOption {
  NoResponseOption(final int value) : super(OptionType.noResponse, value);

  NoResponseOption.parse(final Uint8Buffer bytes)
      : super.parse(OptionType.noResponse, bytes);
}

// TODO(JKRhb): Is this really a class E option?
class OcfAcceptContentFormatVersion extends IntegerOption
    implements OscoreOptionClassE {
  OcfAcceptContentFormatVersion(final int value)
      : super(OptionType.ocfAcceptContentFormatVersion, value);

  OcfAcceptContentFormatVersion.parse(final Uint8Buffer bytes)
      : super.parse(OptionType.ocfAcceptContentFormatVersion, bytes);
}

// TODO(JKRhb): Is this really a class E option?
class OcfContentFormatVersion extends IntegerOption
    implements OscoreOptionClassE {
  OcfContentFormatVersion(final int value)
      : super(OptionType.ocfContentFormatVersion, value);

  OcfContentFormatVersion.parse(final Uint8Buffer bytes)
      : super.parse(OptionType.ocfContentFormatVersion, bytes);
}
