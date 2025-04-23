import 'package:typed_data/typed_data.dart';

import 'coap_option_type.dart';
import 'option.dart';

abstract class EmptyOption extends Option<void> {
  @override
  final Uint8Buffer byteValue = Uint8Buffer();

  @override
  final OptionType type;

  @override
  OptionFormat<Object?> get optionFormat => OptionFormat.empty;

  @override
  String get valueString => '';

  @override
  void get value => {};

  EmptyOption(this.type);
}

class IfNoneMatchOption extends EmptyOption with OscoreOptionClassE {
  IfNoneMatchOption() : super(OptionType.ifNoneMatch);
}

class EdhocOption extends EmptyOption with OscoreOptionClassU {
  EdhocOption() : super(OptionType.edhoc);
}
