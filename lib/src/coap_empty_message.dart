/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Represents an empty CoAP message. An empty message has either
/// the MessageType ACK or RST.
class EmptyMessage extends Message {
  /// Instantiates a new empty message.
  EmptyMessage(int type) : super.withCode(type, Code.empty);

  /// Create a new acknowledgment for the specified message.
  /// Returns the acknowledgment.
  static EmptyMessage newACK(Message message) {
    final EmptyMessage ack = new EmptyMessage(MessageType.ack);
    ack.id = message.id;
    ack.token = CoapConstants.emptyToken;
    ack.destination = message.source;
    return ack;
  }

  /// Create a new reset message for the specified message.
  /// Return the reset.
  static EmptyMessage newRST(Message message) {
    final EmptyMessage rst = new EmptyMessage(MessageType.rst);
    rst.id = message.id;
    rst.token = CoapConstants.emptyToken;
    rst.destination = message.source;
    return rst;
  }
}
