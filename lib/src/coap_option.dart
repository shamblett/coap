/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// This class describes the options of the CoAP messages.
class CoapOption {
  CoapOption(int type) {
    this._type = type;
    this._valueBytes = new typed.Uint8Buffer();
  }

  int _type;

  int get type => _type;

  typed.Uint8Buffer get valueBytes => _valueBytes;

  set valueBytes(typed.Uint8Buffer buff) => _valueBytes = buff;

  set valueBytesList(List<int> bytes) {
    _valueBytes.clear();
    _valueBytes.addAll(bytes);
  }

  /// Value bytes
  typed.Uint8Buffer _valueBytes;

  /// String representation of value bytes
  String get stringValue =>
      new convertor.Utf8Decoder().convert(_valueBytes.toList());

  void _stringEncodeValue(String val) {
    val.codeUnits.forEach((int unit) {
      _valueBytes.add(unit);
    });
  }

  set stringValue(String val) => _stringEncodeValue(val);

  /// Int32 representation of value bytes
  int get intValue {
    final Uint32List buff = new Uint32List.view(_valueBytes.buffer);
    return buff[0];
  }

  set intValue(int val) {
    if (val == 0) {
      _valueBytes.add(0);
    } else {
      final Uint32List buff = new Uint32List(1);
      buff[0] = val;
      _valueBytes.clear();
      _valueBytes.addAll(buff.buffer.asUint8List());
      while (_valueBytes.last == 0) {
        _valueBytes.removeLast();
      }
    }
  }

  /// Int64 representation of value bytes
  int get longValue {
    final Uint64List buff = new Uint64List.view(_valueBytes.buffer);
    return buff[0];
  }

  set longValue(int val) {
    if (val == 0) {
      _valueBytes.add(0);
    } else {
      final Uint64List buff = new Uint64List(1);
      buff[0] = val;
      _valueBytes.clear();
      _valueBytes.addAll(buff.buffer.asUint8List());
      while (_valueBytes.last == 0) {
        _valueBytes.removeLast();
      }
    }
  }

  /// Gets the name of the option that corresponds to its type.
  String get name => CoapOption.stringify(_type);

  /// Gets the value's length in bytes of the option.
  int get length => _valueBytes.lengthInBytes;

  /// Gets the value of the option according to its type.
  dynamic get value {
    switch (_type) {
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
        return _valueBytes.lengthInBytes == 0;
        break;
      default:
        return false;
    }
  }

  String _toValueString() {
    switch (getFormatByType(_type)) {
      case optionFormat.integer:
        return (_type == optionTypeAccept || _type == optionTypeContentFormat)
            ? ("\"" + CoapMediaType.name(intValue) + "\"")
            : intValue.toString();
      case optionFormat.string:
        return "\"" + stringValue + "\"";
      default:
        return _valueBytes.toString();
    }
  }

  /// Returns a human-readable string representation of the option's value.
  String toString() {
    return name + ": " + _toValueString();
  }

  /// Returns the option format based on the option type.
  static optionFormat getFormatByType(int type) {
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
    return result;
  }

  /// Equals override
  bool operator ==(dynamic other) {
    if (other is! CoapOption) {
      return false;
    }
    if (_type != other.type) {
      return false;
    }
    if (length != other.length) {
      return false;
    }
    if (valueBytes.toString() != other.valueBytes.toString()) {
      return false;
    }
    return true;
  }

  /// Creates an option.
  static CoapOption create(int type) {
    switch (type) {
      case optionTypeBlock1:
      case optionTypeBlock2:
        return new CoapBlockOption(type);
      default:
        return new CoapOption(type);
    }
  }

  /// Creates an option.
  static CoapOption createRaw(int type, typed.Uint8Buffer raw) {
    final CoapOption opt = create(type);
    opt._valueBytes = raw;
    return opt;
  }

  /// Creates an option.
  static CoapOption createString(int type, String str) {
    final CoapOption opt = create(type);
    opt.stringValue = str;
    return opt;
  }

  /// Creates an option.
  static CoapOption createVal(int type, int val) {
    final CoapOption opt = create(type);
    opt.intValue = val;
    return opt;
  }

  /// Creates an option.
  static CoapOption createLongVal(int type, int val) {
    final CoapOption opt = create(type);
    opt.longValue = val;
    return opt;
  }

  /// Splits a string into a set of options, e.g. a uri path.
  /// Remove any leading /
  static List<CoapOption> split(int type, String s, String delimiter) {
    final List<CoapOption> opts = new List<CoapOption>();
    final RegExp exp = new RegExp(r"^\/*\/");
    final Match pos = exp.firstMatch(s);
    String tmp = s;
    if (pos != null) {
      tmp = s.substring(pos.end, s.length);
    }
    if (tmp.isNotEmpty) {
      tmp.split(delimiter).forEach((String str) {
        if (delimiter == "/" || str.isNotEmpty) {
          opts.add(CoapOption.createString(type, str));
        }
      });
    }
    return opts;
  }

  /// Joins the string values of a set of options.
  static String join(List<CoapOption> options, String delimiter) {
    String s;
    if (null == options) {
      return s;
    } else {
      String sb = "";
      bool append = false;
      options.forEach((CoapOption opt) {
        if (append) {
          sb += delimiter;
        } else {
          append = true;
        }
        sb += opt.stringValue;
      });
      return sb;
    }
  }

  /// Returns a string representation of the option type.
  static String stringify(int type) {
    switch (type) {
      case optionTypeReserved:
        return "Reserved";
      case optionTypeContentFormat:
        return "Content-Format";
      case optionTypeMaxAge:
        return "Max-Age";
      case optionTypeProxyUri:
        return "Proxy-Uri";
      case optionTypeETag:
        return "ETag";
      case optionTypeUriHost:
        return "Uri-Host";
      case optionTypeLocationPath:
        return "Location-Path";
      case optionTypeUriPort:
        return "Uri-Port";
      case optionTypeLocationQuery:
        return "Location-Query";
      case optionTypeUriPath:
        return "Uri-Path";
      case optionTypeToken:
        return "Token";
      case optionTypeUriQuery:
        return "Uri-Query";
      case optionTypeObserve:
        return "Observe";
      case optionTypeAccept:
        return "Accept";
      case optionTypeIfMatch:
        return "If-Match";
      case optionTypeFencepostDivisor:
        return "Fencepost-Divisor";
      case optionTypeBlock2:
        return "Block2";
      case optionTypeBlock1:
        return "Block1";
      case optionTypeSize2:
        return "Size2";
      case optionTypeSize1:
        return "Size1";
      case optionTypeIfNoneMatch:
        return "If-None-Match";
      case optionTypeProxyScheme:
        return "Proxy-Scheme";
      default:
        return "Unknown ({type})";
    }
  }

  /// Checks whether an option is critical.
  static bool isCritical(int type) {
    return type.isOdd;
  }

  /// Checks whether an option is elective.
  static bool isElective(int type) {
    return type.isEven;
  }

  /// Checks whether an option is unsafe.
  static bool isUnsafe(int type) {
    return (type & 2) > 0;
  }

  /// Checks whether an option is safe.
  static bool isSafe(int type) {
    return !isUnsafe(type);
  }
}
