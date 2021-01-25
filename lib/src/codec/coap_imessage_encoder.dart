/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Provides methods to serialize outgoing messages to byte arrays.
abstract class CoapIMessageEncoder {
  /// Encodes a request into a bytes array.
  typed.Uint8Buffer? encodeRequest(CoapRequest request);

  /// Encodes a response into a bytes array.
  typed.Uint8Buffer? encodeResponse(CoapResponse response);

  /// Encodes an empty message into a bytes array.
  typed.Uint8Buffer? encodeEmpty(CoapEmptyMessage message);

  /// Encodes a CoAP message into a bytes array.
  /// Returns the encoded bytes, or null if the message can not be encoded,
  /// i.e. the message is not a Request, a Response or an EmptyMessage.
  typed.Uint8Buffer? encodeMessage(CoapMessage message);
}
