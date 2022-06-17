/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

import 'package:typed_data/typed_data.dart';

import '../coap_empty_message.dart';
import '../coap_message.dart';
import '../coap_request.dart';
import '../coap_response.dart';

/// Provides methods to serialize outgoing messages to byte arrays.
abstract class CoapIMessageEncoder {
  /// Encodes a request into a bytes array.
  Uint8Buffer encodeRequest(final CoapRequest request);

  /// Encodes a response into a bytes array.
  Uint8Buffer encodeResponse(final CoapResponse response);

  /// Encodes an empty message into a bytes array.
  Uint8Buffer encodeEmpty(final CoapEmptyMessage message);

  /// Encodes a CoAP message into a bytes array.
  /// Returns the encoded bytes, or null if the message can not be encoded,
  /// i.e. the message is not a Request, a Response or an EmptyMessage.
  Uint8Buffer? encodeMessage(final CoapMessage message);
}
