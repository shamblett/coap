import 'package:typed_data/typed_data.dart';

import 'coap_option_type.dart';
import 'option.dart';

abstract class EmptyOption extends Option<void> {
  EmptyOption(this.type);

  @override
  final Uint8Buffer byteValue = Uint8Buffer();

  @override
  OptionFormat<Object?> get optionFormat => OptionFormat.empty;

  @override
  final OptionType type;

  @override
  String get valueString => '';

  @override
  void get value => {};
}

class IfNoneMatchOption extends EmptyOption implements OscoreOptionClassE {
  IfNoneMatchOption() : super(OptionType.ifNoneMatch);
}

class EdhocOption extends EmptyOption implements OscoreOptionClassU {
  EdhocOption() : super(OptionType.edhoc);
}
