/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Represents an empty CoAP message. An empty message has either
/// the MessageType ACK or RST.
class CoapEmptyMessage extends CoapMessage {
  /// Instantiates a new empty message.
  CoapEmptyMessage(CoapEventBus eventBus, int? type) : super.withCode(eventBus, type, CoapCode.empty);

  /// Create a new acknowledgment for the specified message.
  /// Returns the acknowledgment.
  static CoapEmptyMessage newACK(CoapEventBus eventBus, CoapMessage message) {
    final ack = CoapEmptyMessage(eventBus, CoapMessageType.ack);
    ack.id = message.id;
    ack.token = CoapConstants.emptyToken;
    ack.destination = message.source;
    return ack;
  }

  /// Create a new reset message for the specified message.
  /// Return the reset.
  static CoapEmptyMessage newRST(CoapEventBus eventBus, CoapMessage message) {
    final rst = CoapEmptyMessage(eventBus, CoapMessageType.rst);
    rst.id = message.id;
    rst.token = CoapConstants.emptyToken;
    rst.destination = message.source;
    return rst;
  }

  /// Create a new empty message confirmable for the specified message.
  /// Return the empty
  static CoapEmptyMessage newCon(CoapEventBus eventBus, CoapMessage message) {
    final ep = CoapEmptyMessage(eventBus, CoapMessageType.con);
    ep.token = CoapConstants.emptyToken;
    ep.destination = message.source;
    return ep;
  }
}
