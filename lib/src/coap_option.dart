/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// This class describes the options of the CoAP messages.
class Option {
  Option(int type) {
    this._type = type;
    this._valueBytes = new typed.Uint8Buffer();
  }

  int _type;

  int get type => _type;

  typed.Uint8Buffer get valueBytes => _valueBytes;

  set valueBytes(typed.Uint8Buffer buff) => _valueBytes = buff;

  /// Value bytes in network byte order (big-endian)
  typed.Uint8Buffer _valueBytes;

  /// String representation of value bytes
  String get stringValue => _valueBytes.toString();

  void _stringEncodeValue(String val) {
    val.codeUnits.forEach((int unit) {
      _valueBytes.add(unit);
    });
  }

  set stringValue(String val) => _stringEncodeValue(val);

  /// Int32 representation of value bytes
  int get intValue {
    final typed.Uint32Buffer buff = new typed.Uint32Buffer();
    buff.addAll(_valueBytes);
    return buff[0];
  }

  set intValue(int val) {
    final typed.Uint32Buffer buff = new typed.Uint32Buffer();
    buff[0] = val;
    _valueBytes.clear();
    _valueBytes.addAll(buff);
  }

  /// Int64 representation of value bytes
  int get longValue {
    final typed.Uint64Buffer buff = new typed.Uint64Buffer();
    buff.addAll(_valueBytes);
    return buff[0];
  }

  set longValue(int val) {
    final typed.Uint64Buffer buff = new typed.Uint64Buffer();
    buff[0] = val;
    _valueBytes.clear();
    _valueBytes.addAll(buff);
  }

  /// Gets the name of the option that corresponds to its type.
  String name() {
    return _type.toString();
  }

  /// Gets the value's length in bytes of the option.
  int length() {
    return _valueBytes.length;
  }

  /// Gets the value of the option according to its type.
  dynamic value(int type) {
    switch (type) {
      case optionTypeReserved:
        return null;
      case optionTypeContentType:
      case optionTypeMaxAge:
      case optionTypeUriPort:
      case optionTypeObserve:
      case optionTypeBlock2:
      case optionTypeBlock1:
      case optionTypeAccept:
      case optionTypeFencepostDivisor:
        return intValue;
        break;
      case optionTypeProxyUri:
      case optionTypeETag:
      case optionTypeUriHost:
      case optionTypeLocationPath:
      case optionTypeLocationQuery:
      case optionTypeUriPath:
      case optionTypeToken:
      case optionTypeUriQuery:
      case optionTypeIfMatch:
      case optionTypeIfNoneMatch:
        return stringValue;
        break;
      default:
        return null;
    }
  }

  /// Gets a value indicating whether the option has a default value according to the draft.
  bool isDefault() {
    switch (_type) {
      case optionTypeMaxAge:
        return intValue == CoapConstants.defaultMaxAge;
        break;
      case optionTypeToken:
        return _valueBytes.length == 0;
        break;
      default:
        return false;
    }
  }

  String _toValueString() {
    switch (_getFormatByType(_type)) {
      case optionFormat.integer:
        return (_type == optionTypeAccept || _type == optionTypeContentFormat)
            ? ("\"" + MediaType.name(intValue) + "\"")
            : intValue.toString();
      case optionFormat.string:
        return "\"" + stringValue + "\"";
      default:
        return _valueBytes.toString();
    }
  }

  /// Returns a human-readable string representation of the option's value.
  String toString() {
    return name() + ": " + _toValueString();
  }

  /// Returns the option format based on the option type.
  optionFormat _getFormatByType(int type) {
    switch (type) {
      case optionTypeContentFormat:
      case optionTypeMaxAge:
      case optionTypeUriPort:
      case optionTypeObserve:
      case optionTypeBlock2:
      case optionTypeBlock1:
      case optionTypeSize2:
      case optionTypeSize1:
      case optionTypeIfNoneMatch:
      case optionTypeAccept:
      case optionTypeFencepostDivisor:
        return optionFormat.integer;
        break;
      case optionTypeUriHost:
      case optionTypeUriPath:
      case optionTypeUriQuery:
      case optionTypeLocationPath:
      case optionTypeLocationQuery:
      case optionTypeProxyUri:
      case optionTypeProxyScheme:
      case optionTypeToken:
        return optionFormat.string;
        break;
      case optionTypeETag:
      case optionTypeIfMatch:
        return optionFormat.opaque;
        break;
      default:
        return optionFormat.unknown;
    }
  }

  /// Hash code override
  int get hashCode {
    const int prime = 31;
    int result = 1;
    result = prime * result + _type;
  }

  /// Equals override
  bool operator ==(dynamic other) {
    if (other is! Option) {
      return false;
    }
    if (_type != other.type) {
      return false;
    }
    return true;
  }

  /// Creates an option.
  static Option create(OptionType type) {
    switch (type) {
      case OptionType.Block1:
      case OptionType.Block2:
        return new BlockOption(type);
      default:
        return new Option(type);
    }
  }
}
