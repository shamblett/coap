/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 08/05/2017
 * Copyright :  S.Hamblett
 */

import 'package:meta/meta.dart';

/// Class for linkformat attributes.
@immutable
class CoapLinkAttribute {
  final String _name;

  final Object? _value;

  /// Name
  String get name => _name;

  /// Value
  Object? get value => _value;

  /// Value as integer
  int? get valueAsInt => _value is int ? _value as int? : -1;

  /// Value as String
  String? get valueAsString => _value is String ? _value as String? : null;

  @override
  int get hashCode => _name.hashCode;

  /// Initializes an attribute.
  const CoapLinkAttribute(this._name, this._value);

  /// Serializes this attribute into its string representation.
  void serialize(final StringBuffer builder) {
    // check if there's something to write
    if (_value != null) {
      if (_value is bool) {
        // flag attribute
        builder.write(_name);
      } else {
        // name-value-pair
        builder.write('$_name=');
        if (_value is String) {
          builder.write('"$_value"');
        } else if (_value is int) {
          builder.write(_value);
        } else {
          throw FormatException(
            'Serializing attribute of unexpected type: '
            '$_name ${_value.runtimeType}',
          );
        }
      }
    }
  }

  @override
  String toString() => 'name: $_name  value: $_value';

  @override
  bool operator ==(final Object other) {
    if (other is! CoapLinkAttribute) {
      return false;
    }
    return _name == other.name && _value == other.value;
  }
}
