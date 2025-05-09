import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:typed_data/typed_data.dart';

import 'coap_option_type.dart';
import 'option.dart';

abstract class StringOption extends Option<String> {
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

  StringOption(this.type, final String value)
    : byteValue = Uint8Buffer()..addAll(utf8.encode(value));

  StringOption.parse(this.type, final Uint8Buffer? bytes)
    : byteValue = Uint8Buffer()..addAll(bytes ?? []);
}

abstract class QueryOption extends StringOption {
  @internal
  MapEntry<String, String?> get queryParameter {
    final parameter = this.value.split('=');
    final key = parameter.first;
    final value = parameter.length > 1 ? parameter.sublist(1).join('=') : null;

    return MapEntry(key, value);
  }

  QueryOption(super.type, super.value);

  QueryOption.parse(super.type, Uint8Buffer super.bytes) : super.parse();
}

abstract class PathOption extends StringOption {
  @internal
  String get pathSegment => "/${value.replaceAll('/', '%2F')}";

  PathOption(super.type, super.value) {
    if (value == '..' || value == '.') {
      throw FormatException(
        'The value of a $name Option must not be "." or ".."',
      );
    }
  }

  PathOption.parse(super.type, Uint8Buffer super.bytes) : super.parse();
}

class LocationPathOption extends PathOption with OscoreOptionClassE {
  LocationPathOption(final String value)
    : super(OptionType.locationPath, value);

  LocationPathOption.parse(final Uint8Buffer bytes)
    : super.parse(OptionType.locationPath, bytes);
}

class UriHostOption extends StringOption with OscoreOptionClassU {
  UriHostOption(final String value) : super(OptionType.uriHost, value);

  UriHostOption.parse(final Uint8Buffer bytes)
    : super.parse(OptionType.uriHost, bytes);
}

class UriPathOption extends PathOption with OscoreOptionClassE {
  UriPathOption(final String value) : super(OptionType.uriPath, value);

  UriPathOption.parse(final Uint8Buffer bytes)
    : super.parse(OptionType.uriPath, bytes);
}

class UriQueryOption extends QueryOption with OscoreOptionClassE {
  UriQueryOption(final String value) : super(OptionType.uriQuery, value);

  UriQueryOption.parse(final Uint8Buffer bytes)
    : super.parse(OptionType.uriQuery, bytes);
}

class LocationQueryOption extends QueryOption with OscoreOptionClassE {
  LocationQueryOption(final String value)
    : super(OptionType.locationQuery, value);

  LocationQueryOption.parse(final Uint8Buffer bytes)
    : super.parse(OptionType.locationQuery, bytes);
}

class ProxyUriOption extends StringOption with OscoreOptionClassU {
  ProxyUriOption(final String value) : super(OptionType.proxyUri, value);

  ProxyUriOption.parse(final Uint8Buffer bytes)
    : super.parse(OptionType.proxyUri, bytes);
}

class ProxySchemeOption extends StringOption with OscoreOptionClassU {
  ProxySchemeOption(final String value) : super(OptionType.proxyUri, value);

  ProxySchemeOption.parse(final Uint8Buffer bytes)
    : super.parse(OptionType.proxyUri, bytes);
}
