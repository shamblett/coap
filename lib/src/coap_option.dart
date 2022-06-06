/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:typed_data/typed_data.dart';

import 'coap_block_option.dart';
import 'coap_constants.dart';
import 'coap_media_type.dart';
import 'coap_option_type.dart';
import 'util/coap_byte_array_util.dart';

/// This class describes the options of the CoAP messages.
class CoapOption {
  /// Construction
  CoapOption(this._type) : _buffer = Uint8Buffer();

  final OptionType _type;

  /// Type
  OptionType get type => _type;

  final Uint8Buffer _buffer;

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
  Uint8Buffer get byteValue => _buffer;

  /// raw byte representation of value bytes
  set byteValue(Uint8Buffer val) {
    _buffer.clear();
    _buffer.addAll(val);
  }

  /// String representation of value bytes
  String get stringValue => const Utf8Decoder().convert(_buffer.toList());

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
  String get name => _type.name;

  /// Gets the value's length in bytes of the option.
  int get length => _buffer.lengthInBytes;

  /// Gets the value of the option according to its type.
  dynamic get value {
    switch (_type.optionFormat) {
      case OptionFormat.integer:
        return intValue;
      case OptionFormat.string:
        return stringValue;
      default:
        return null;
    }
  }

  /// Checks whether the option value is the default.
  bool isDefault() {
    if (_type == OptionType.maxAge) {
      return intValue == CoapConstants.defaultMaxAge;
    }
    return false;
  }

  String _toValueString() {
    switch (_type.optionFormat) {
      case OptionFormat.integer:
        return (_type == OptionType.accept || _type == OptionType.contentFormat)
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

  /// Creates an option.
  static CoapOption create(int optionNumber) {
    final type = OptionType.fromTypeNumber(optionNumber);
    switch (type) {
      case OptionType.block1:
      case OptionType.block2:
        return CoapBlockOption(type);
      default:
        return CoapOption(type);
    }
  }

  /// Creates an option.
  static CoapOption createRaw(OptionType type, Uint8Buffer raw) {
    return create(type.optionNumber)..byteValue = raw;
  }

  /// Creates an option.
  static CoapOption createString(OptionType type, String str) {
    return create(type.optionNumber)..stringValue = str;
  }

  /// Creates a query option (shorthand because it's so common).
  static CoapOption createUriQuery(String str) {
    return create(OptionType.uriQuery.optionNumber)..stringValue = str;
  }

  /// Creates an option.
  static CoapOption createVal(OptionType type, int val) {
    return create(type.optionNumber)..intValue = val;
  }

  /// Splits a string into a set of options, e.g. a uri path.
  /// Remove any leading /
  static List<CoapOption> split(OptionType type, String s, String delimiter) {
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
}
