import 'package:convert/convert.dart';
import 'package:typed_data/typed_data.dart';

import 'coap_option_type.dart';
import 'option.dart';

abstract class OpaqueOption extends Option<Uint8Buffer> {
  OpaqueOption(this.type, final Uint8Buffer bytes) : value = bytes;

  @override
  final Uint8Buffer value;

  @override
  Uint8Buffer get byteValue => value;

  @override
  final optionFormat = OptionFormat.opaque;

  @override
  final OptionType type;

  @override
  String get valueString => hex.encode(byteValue.toList());
}

class IfMatchOption extends OpaqueOption with OscoreOptionClassE {
  IfMatchOption(final Uint8Buffer value) : super(OptionType.ifMatch, value);
}

class ETagOption extends OpaqueOption with OscoreOptionClassE {
  ETagOption(final Uint8Buffer value) : super(OptionType.eTag, value);
}

/// The Echo Option provides a lightweight challenge-response mechanism for
/// CoAP that enables a CoAP server to verify the freshness of a request.
///
/// Defined in [RFC 9175, section 2.2.1].
///
/// [RFC 9175, section 2.2.1]: https://datatracker.ietf.org/doc/html/rfc9175#section-2.2.1
class EchoOption extends OpaqueOption
    with OscoreOptionClassE, OscoreOptionClassU {
  EchoOption(final Uint8Buffer value) : super(OptionType.echo, value);
}

/// The Request-Tag Option can be used for identifying request
/// bodies, similar to the [ETagOption] , but ephemeral and set by the CoAP
/// client.
///
/// Defined in [RFC 9175, section 3.2.1].
///
/// [RFC 9175, section 3.2.1]: https://datatracker.ietf.org/doc/html/rfc9175#section-3.2.1
class RequestTagOption extends OpaqueOption
    with OscoreOptionClassE, OscoreOptionClassU {
  RequestTagOption(final Uint8Buffer value)
      : super(OptionType.requestTag, value);
}
