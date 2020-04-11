/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// This class describes the options of the CoAP messages.
class CoapOption {
  /// Construction
  CoapOption(this._type) {
    valueBytes = typed.Uint8Buffer();
  }

  final int _type;

  /// Type
  int get type => _type;

  /// Value bytes
  typed.Uint8Buffer valueBytes;

  /// From list
  set valueBytesList(List<int> bytes) {
    valueBytes.clear();
    valueBytes.addAll(bytes);
  }

  /// String representation of value bytes
  String get stringValue =>
      const convertor.Utf8Decoder().convert(valueBytes.toList());

  set stringValue(String val) => valueBytes.addAll(val.codeUnits);

  /// Integer value
  int get intValue {
    if (valueBytes.isEmpty) {
      return 0;
    }
    if (valueBytes.length == 1) {
      return valueBytes[0];
    } else if (valueBytes.length == 2) {
      final buff = Uint16List.view(valueBytes.buffer);
      return buff[0];
    } else {
      final buff = Uint32List.view(valueBytes.buffer);
      return buff[0];
    }
  }

  set intValue(int val) {
    if (val == 0) {
      valueBytes.add(0);
    } else {
      valueBytes.clear();
      if (val <= 255) {
        valueBytes.add(val);
      } else if (val <= 65535) {
        final buff = Uint16List(1);
        buff[0] = val;
        valueBytes.addAll(buff.buffer.asUint8List());
      } else {
        final buff = Uint32List(1);
        buff[0] = val;
        valueBytes.addAll(buff.buffer.asUint8List());
      }
    }
  }

  /// Int64 representation of value bytes
  int get longValue {
    final buff = Uint64List.view(valueBytes.buffer);
    return buff[0];
  }

  set longValue(int val) {
    if (val == 0) {
      valueBytes.add(0);
    } else {
      final buff = Uint64List(1);
      buff[0] = val;
      valueBytes.clear();
      valueBytes.addAll(buff.buffer.asUint8List());
    }
  }

  /// Gets the name of the option that corresponds to its type.
  String get name => CoapOption.stringify(_type);

  /// Gets the value's length in bytes of the option.
  int get length => valueBytes.lengthInBytes;

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

  /// Gets a value indicating whether the option has a default value
  /// according to the draft.
  bool isDefault() {
    switch (_type) {
      case optionTypeMaxAge:
        return intValue == CoapConstants.defaultMaxAge;
        break;
      case optionTypeToken:
        return valueBytes.lengthInBytes == 0;
        break;
      default:
        return false;
    }
  }

  String _toValueString() {
    switch (getFormatByType(_type)) {
      case optionFormat.integer:
        return (_type == optionTypeAccept || _type == optionTypeContentFormat)
            ? ('${CoapMediaType.name(intValue)}')
            : intValue.toString();
      case optionFormat.string:
        return '$stringValue';
      default:
        return CoapByteArrayUtil.toHexString(valueBytes);
    }
  }

  @override
  String toString() => '$name: ${_toValueString()}';

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

  @override
  int get hashCode {
    const prime = 31;
    var result = 1;
    return result = prime * result + _type;
  }

  @override
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
        return CoapBlockOption(type);
      default:
        return CoapOption(type);
    }
  }

  /// Creates an option.
  static CoapOption createRaw(int type, typed.Uint8Buffer raw) {
    final opt = create(type);
    opt.valueBytes = raw;
    return opt;
  }

  /// Creates an option.
  static CoapOption createString(int type, String str) {
    final opt = create(type);
    opt.stringValue = str;
    return opt;
  }

  /// Creates an option.
  static CoapOption createVal(int type, int val) {
    final opt = create(type);
    opt.intValue = val;
    return opt;
  }

  /// Creates an option.
  static CoapOption createLongVal(int type, int val) {
    final opt = create(type);
    opt.longValue = val;
    return opt;
  }

  /// Splits a string into a set of options, e.g. a uri path.
  /// Remove any leading /
  static List<CoapOption> split(int type, String s, String delimiter) {
    final opts = <CoapOption>[];
    final exp = RegExp(r'^\/*\/');
    final Match pos = exp.firstMatch(s);
    var tmp = s;
    if (pos != null) {
      tmp = s.substring(pos.end, s.length);
    }
    if (tmp.isNotEmpty) {
      for (final str in tmp.split(delimiter)) {
        if (delimiter == '/' || str.isNotEmpty) {
          opts.add(CoapOption.createString(type, str));
        }
      }
    }
    return opts;
  }

  /// Joins the string values of a set of options.
  static String join(List<CoapOption> options, String delimiter) {
    String s;
    if (null == options) {
      return s;
    } else {
      final sb = StringBuffer();
      var append = false;
      for (final opt in options) {
        if (append) {
          sb.write(delimiter);
        } else {
          append = true;
        }
        sb.write(opt.stringValue);
      }
      return sb.toString();
    }
  }

  /// Returns a string representation of the option type.
  static String stringify(int type) {
    switch (type) {
      case optionTypeReserved:
        return 'Reserved';
      case optionTypeContentFormat:
        return 'Content-Format';
      case optionTypeMaxAge:
        return 'Max-Age';
      case optionTypeProxyUri:
        return 'Proxy-Uri';
      case optionTypeETag:
        return 'ETag';
      case optionTypeUriHost:
        return 'Uri-Host';
      case optionTypeLocationPath:
        return 'Location-Path';
      case optionTypeUriPort:
        return 'Uri-Port';
      case optionTypeLocationQuery:
        return 'Location-Query';
      case optionTypeUriPath:
        return 'Uri-Path';
      case optionTypeToken:
        return 'Token';
      case optionTypeUriQuery:
        return 'Uri-Query';
      case optionTypeObserve:
        return 'Observe';
      case optionTypeAccept:
        return 'Accept';
      case optionTypeIfMatch:
        return 'If-Match';
      case optionTypeFencepostDivisor:
        return 'Fencepost-Divisor';
      case optionTypeBlock2:
        return 'Block2';
      case optionTypeBlock1:
        return 'Block1';
      case optionTypeSize2:
        return 'Size2';
      case optionTypeSize1:
        return 'Size1';
      case optionTypeIfNoneMatch:
        return 'If-None-Match';
      case optionTypeProxyScheme:
        return 'Proxy-Scheme';
      default:
        return 'Unknown ({type})';
    }
  }

  /// Checks whether an option is critical.
  static bool isCritical(int type) => type.isOdd;

  /// Checks whether an option is elective.
  static bool isElective(int type) => type.isEven;

  /// Checks whether an option is unsafe.
  static bool isUnsafe(int type) => (type & 2) > 0;

  /// Checks whether an option is safe.
  static bool isSafe(int type) => !isUnsafe(type);
}
