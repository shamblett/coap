import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:typed_data/typed_data.dart';

import 'coap_option_type.dart';
import 'option.dart';

abstract class StringOption extends Option<String> {
  StringOption(this.type, final String value)
      : byteValue = Uint8Buffer()..addAll(utf8.encode(value));

  StringOption.parse(this.type, final Uint8Buffer? bytes)
      : byteValue = Uint8Buffer()..addAll(bytes ?? []);

  @override
  final Uint8Buffer byteValue;

  @override
  final optionFormat = OptionFormat.string;

  @override
  final OptionType type;

  @override
  String get value => const Utf8Decoder().convert(byteValue.toList());

  @override
  String get valueString => value;
}

abstract class QueryOption extends StringOption {
  QueryOption(super.type, super.value);

  QueryOption.parse(super.type, Uint8Buffer super.bytes) : super.parse();

  @internal
  MapEntry<String, String?> get queryParameter {
    final parameter = this.value.split('=');
    final key = parameter[0];
    final value = parameter.length > 1 ? parameter.sublist(1).join('=') : null;

    return MapEntry(key, value);
  }
}

class LocationPathOption extends StringOption implements OscoreOptionClassE {
  LocationPathOption(final String value)
      : super(OptionType.locationPath, value) {
    if (value == '..' || value == '.') {
      throw ArgumentError.value(
        value,
        'LocationPathOption'
        'The value of a Location-Path Option must not be "." or ".."',
      );
    }
  }

  LocationPathOption.parse(final Uint8Buffer bytes)
      : super.parse(OptionType.locationPath, bytes);
}

class UriHostOption extends StringOption implements OscoreOptionClassU {
  UriHostOption(final String value) : super(OptionType.uriHost, value);

  UriHostOption.parse(final Uint8Buffer bytes)
      : super.parse(OptionType.uriHost, bytes);
}

class UriPathOption extends StringOption implements OscoreOptionClassE {
  UriPathOption(final String value) : super(OptionType.uriPath, value) {
    if (value == '.' || value == '..') {
      throw ArgumentError.value(
        value,
        'UriPathOption',
        'The value of a Uri-Path Option must not be "." or ".."',
      );
    }
  }

  UriPathOption.parse(final Uint8Buffer bytes)
      : super.parse(OptionType.uriPath, bytes);
}

class UriQueryOption extends QueryOption implements OscoreOptionClassE {
  UriQueryOption(final String value) : super(OptionType.uriQuery, value);

  UriQueryOption.parse(final Uint8Buffer bytes)
      : super.parse(OptionType.uriQuery, bytes);
}

class LocationQueryOption extends QueryOption implements OscoreOptionClassE {
  LocationQueryOption(final String value)
      : super(OptionType.locationQuery, value);

  LocationQueryOption.parse(final Uint8Buffer bytes)
      : super.parse(OptionType.locationQuery, bytes);
}

class ProxyUriOption extends StringOption implements OscoreOptionClassU {
  ProxyUriOption(final String value) : super(OptionType.proxyUri, value);

  ProxyUriOption.parse(final Uint8Buffer bytes)
      : super.parse(OptionType.proxyUri, bytes);
}

class ProxySchemeOption extends StringOption implements OscoreOptionClassU {
  ProxySchemeOption(final String value) : super(OptionType.proxyUri, value);

  ProxySchemeOption.parse(final Uint8Buffer bytes)
      : super.parse(OptionType.proxyUri, bytes);
}
