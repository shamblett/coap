/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Provides methods to parse incoming byte arrays to messages.
abstract class IMessageDecoder {
  /// Checks if the decoding message is well formed.
  bool get isWellFormed;

  /// Checks if the decoding message is a reply.
  bool get isReply;

  /// Checks if the decoding message is a request.
  bool get isRequest;

  /// Checks if the decoding message is a response.
  bool get isResponse;

  /// Checks if the decoding message is an empty message.
  bool get isEmpty;

  /// Gets the version of the decoding message.
  int get version;

  /// Gets the id of the decoding message.
  int get id;

  /// Decodes as a Request.
  Request decodeRequest();

  /// Decodes as a Response.
  Response decodeResponse();

  /// Decodes as an EmptyMessage.
  EmptyMessage decodeEmptyMessage();

  /// Decodes as a CoAP message.
  Message decode();
}
