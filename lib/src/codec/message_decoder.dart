import 'package:typed_data/typed_data.dart';

import '../coap_message.dart';

// TODO(JKRhb): We could also use single functions for deserialization
// ignore: one_member_abstracts
abstract class MessageDecoder {
  CoapMessage? parseMessage(final Uint8Buffer data);
}
