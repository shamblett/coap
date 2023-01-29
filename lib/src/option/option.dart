import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:typed_data/typed_data.dart';

import 'coap_option_type.dart';

/// This class describes the options of the CoAP messages.
@immutable
abstract class Option<T> {
  Option() {
    _validate();
  }

  void _validate() {
    final isValid = length >= minLength && length <= maxLength;

    if (isValid) {
      return;
    }

    final errorMessage =
        'Invalid length (expected: $minLength-$maxLength bytes, '
        'actual: $length bytes) for option $type, option number: $optionNumber';

    if (type.isCritical) {
      throw UnknownCriticalOptionException(optionNumber, errorMessage);
    } else {
      throw UnknownElectiveOptionException(optionNumber, errorMessage);
    }
  }

  /// The assigned number of this [Option].
  int get optionNumber => type.optionNumber;

  /// The minimum length of this [Option] in bytes.
  int get minLength => type.minLength;

  /// The maximum length of this [Option] in bytes.
  int get maxLength => type.maxLength;

  /// Indicates if this [Option] is repeatable, i.e. if it can appear more than
  /// once in a CoAP message.
  bool get repeatable => type.repeatable;

  /// The format of this [Option].
  ///
  /// Can be one of [OptionFormat.empty], [OptionFormat.integer],
  /// [OptionFormat.opaque], [OptionFormat.string], or [OptionFormat.oscore].
  ///
  /// [OptionFormat.oscore] is a special format only used for the OSCORE option
  /// ([RFC 8613])
  ///
  /// [RFC 8613]: https://www.rfc-editor.org/rfc/rfc8613.html
  OptionFormat<T> get optionFormat;

  /// Returns a byte representation of this [Option]'s [value].
  Uint8Buffer get byteValue;

  /// Returns a [String] representation of this [Option]'s [value].
  String get valueString;

  /// Type
  OptionType get type;

  /// The typed value of this [Option].
  T get value;

  /// Gets the name of the option that corresponds to its type.
  String get name => type.optionName;

  /// Gets the value's length in bytes of the option.
  int get length => byteValue.lengthInBytes;

  @override
  int get hashCode => Object.hash(type, byteValue);

  @override
  bool operator ==(final Object other) =>
      other is Option &&
      optionFormat == other.optionFormat &&
      type == other.type &&
      byteValue.equals(other.byteValue);

  @override
  String toString() => '$name: $valueString';

  bool get valid => length >= type.minLength && length <= type.maxLength;
}

/// Mixin for an Oscore class E option (encrypted and integrity protected).
/// See [RFC 8613, section 4.1.1].
///
/// Also applies to all options that are unknown or or for which OSCORE
/// processing is not defined (see [RFC 8613, section 4.1]).
///
/// [RFC 8613, section 4.1.1]: https://www.rfc-editor.org/rfc/rfc8613.html#section-4.1.1
/// [RFC 8613, section 4.1]: https://www.rfc-editor.org/rfc/rfc8613.html#section-4.1
/// https://www.rfc-editor.org/rfc/rfc8613.html#section-4.1
mixin OscoreOptionClassE {}

/// Interface for an Oscore class I option (integrity protected only). See
/// [RFC 8613, section 4.1.2].
///
/// Outer option message fields (Class U or I) are used to support proxy
/// operations.
///
/// [RFC 8613, section 4.1.2]: https://www.rfc-editor.org/rfc/rfc8613.html#section-4.1.2
mixin OscoreOptionClassI {}

/// Mixin for an Oscore class U option (unprotected). See
/// [RFC 8613, section 4.1.2].
///
/// Outer option message fields (Class U or I) are used to support proxy
/// operations.
///
/// [RFC 8613, section 4.1.2]: https://www.rfc-editor.org/rfc/rfc8613.html#section-4.1.2
mixin OscoreOptionClassU {}
