/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Represents a draft version of CoAP specification.
abstract class ISpec {
  /// Gets the name of this draft.
  String get name;

  /// Gets the default CoAP port in this draft.
  int get defaultPort;

  /// Encodes a CoAP message into a bytes array.
  /// Returns the encoded bytes, or null if the message can not be encoded,
  /// i.e. the message is not a Request, a Response or an EmptyMessage.
  typed.Uint8Buffer encode(Message msg);

  /// Decodes a CoAP message from a bytes array.
  /// Returns the decoded message, or null if the bytes array can not be recognized.
  Message decode(typed.Uint8Buffer bytes);

  /// Gets an IMessageEncoder.
  IMessageEncoder newMessageEncoder();

  /// Gets an IMessageDecoder.
  IMessageDecoder newMessageDecoder(typed.Uint8Buffer data);
}
