/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 08/05/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Class for linkformat attributes.
class CoapLinkAttribute {
  /// Initializes an attribute.
  CoapLinkAttribute(String name, Object value) {
    _name = name;
    _value = value;
  }

  final CoapILogger _log = CoapLogManager().logger;

  String _name;

  /// Name
  String get name => _name;

  Object _value;

  /// Value
  Object get value => _value;

  /// Value as integer
  int get valueAsInt => _value is int ? _value : -1;

  /// Value as String
  String get valueAsString => _value is String ? _value : null;

  /// Serializes this attribute into its string representation.
  void serialize(StringBuffer builder) {
    // check if there's something to write
    if (_name != null && _value != null) {
      if (_value is bool) {
        // flag attribute
        builder.write(_name);
      } else {
        // name-value-pair
        builder.write(_name);
        builder.write('=');
        if (_value is String) {
          builder.write('"');
          builder.write(_value);
          builder.write('"');
        } else if (_value is int) {
          builder.write(_value);
        } else {
          _log.error('Serializing attribute of unexpected type: '
              '$_name ${_value.runtimeType}');
        }
      }
    }
  }

  @override
  String toString() => 'name: $_name  value: $_value';

  @override
  bool operator ==(Object other) {
    if (other is CoapLinkAttribute) {
      if (_name == other.name) {
        if (_value == other.value) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  int get hashCode => name.hashCode;
}
