import 'package:typed_data/typed_data.dart';

import '../coap_message.dart';

// TODO(JKRhb): We could also use single functions for serialization
// ignore: one_member_abstracts
abstract class MessageEncoder {
  Uint8Buffer serializeMessage(final CoapMessage message);
}
