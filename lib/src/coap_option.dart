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
  CoapOption(this._type) : _buffer = typed.Uint8Buffer();

  final int _type;

  /// Type
  int get type => _type;

  final typed.Uint8Buffer _buffer;

  @override
  int get hashCode => Object.hash(_type, _buffer);

  @override
  bool operator ==(Object other) {
    if (other is! CoapOption) {
      return false;
    }
    return _type == other._type && _buffer.equals(other._buffer);
  }

  /// Value in bytes
  typed.Uint8Buffer get byteValue => _buffer;

  /// raw byte representation of value bytes
  set byteValue(typed.Uint8Buffer val) {
    _buffer.clear();
    _buffer.addAll(val);
  }

  /// String representation of value bytes
  String get stringValue =>
      const convertor.Utf8Decoder().convert(_buffer.toList());

  set stringValue(String val) {
    _buffer.clear();
    _buffer.addAll(val.codeUnits);
  }

  /// Int representation of value bytes
  int get intValue {
    switch (_buffer.length) {
      case 0:
        return 0;
      case 1:
        return _buffer[0];
      case 2:
        return Uint16List.view(_buffer.buffer)[0];
      case 3:
      case 4:
        return Uint32List.view(_buffer.buffer)[0];
      default:
        return Uint64List.view(_buffer.buffer)[0];
    }
  }

  set intValue(int val) {
    _buffer.clear();
    if (val < 0 || val >= (1 << 32)) {
      final buff = Uint64List(1)..first = val;
      _buffer.addAll(buff.buffer.asUint8List());
    } else if (val < (1 << 8)) {
      _buffer.add(val);
    } else if (val < (1 << 16)) {
      final buff = Uint16List(1)..first = val;
      _buffer.addAll(buff.buffer.asUint8List());
    } else {
      final buff = Uint32List(1)..first = val;
      _buffer.addAll(buff.buffer.asUint8List());
    }
  }

  /// Gets the name of the option that corresponds to its type.
  String get name => CoapOption.stringify(_type);

  /// Gets the value's length in bytes of the option.
  int get length => _buffer.lengthInBytes;

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
        return intValue;
      case optionTypeProxyUri:
      case optionTypeETag:
      case optionTypeUriHost:
      case optionTypeLocationPath:
      case optionTypeLocationQuery:
      case optionTypeUriPath:
      case optionTypeUriQuery:
      case optionTypeIfMatch:
      case optionTypeIfNoneMatch:
        return stringValue;
      default:
        return null;
    }
  }

  /// Checks whether the option value is the default.
  bool isDefault() {
    switch (_type) {
      case optionTypeMaxAge:
        return intValue == CoapConstants.defaultMaxAge;
      default:
        return false;
    }
  }

  String _toValueString() {
    switch (getFormatByType(_type)) {
      case OptionFormat.integer:
        return (_type == optionTypeAccept || _type == optionTypeContentFormat)
            ? CoapMediaType.name(intValue)
            : intValue.toString();
      case OptionFormat.string:
        return stringValue;
      default:
        return CoapByteArrayUtil.toHexString(_buffer);
    }
  }

  @override
  String toString() => '$name: ${_toValueString()}';

  /// Returns the option format based on the option type.
  static OptionFormat getFormatByType(int type) {
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
        return OptionFormat.integer;
      case optionTypeUriHost:
      case optionTypeUriPath:
      case optionTypeUriQuery:
      case optionTypeLocationPath:
      case optionTypeLocationQuery:
      case optionTypeProxyUri:
      case optionTypeProxyScheme:
        return OptionFormat.string;
      case optionTypeETag:
      case optionTypeIfMatch:
        return OptionFormat.opaque;
      default:
        return OptionFormat.unknown;
    }
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
    return create(type)..byteValue = raw;
  }

  /// Creates an option.
  static CoapOption createString(int type, String str) {
    return create(type)..stringValue = str;
  }

  /// Creates a query option (shorthand because it's so common).
  static CoapOption createUriQuery(String str) {
    return create(optionTypeUriQuery)..stringValue = str;
  }

  /// Creates an option.
  static CoapOption createVal(int type, int val) {
    return create(type)..intValue = val;
  }

  /// Splits a string into a set of options, e.g. a uri path.
  /// Remove any leading /
  static List<CoapOption> split(int type, String s, String delimiter) {
    final opts = <CoapOption>[];
    final exp = RegExp(r'^\/*\/');
    final Match? pos = exp.firstMatch(s);
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
  static String? join(List<CoapOption>? options, String delimiter) {
    if (options == null) {
      return null;
    }
    final sb = StringBuffer();
    for (final opt in options) {
      if (opt != options.first) {
        sb.write(delimiter);
      }
      sb.write(opt.stringValue);
    }
    return sb.toString();
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
      case optionTypeUriQuery:
        return 'Uri-Query';
      case optionTypeObserve:
        return 'Observe';
      case optionTypeAccept:
        return 'Accept';
      case optionTypeIfMatch:
        return 'If-Match';
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
        return 'Unknown ($type)';
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
