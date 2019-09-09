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
  CoapEmptyMessage(int type) : super.withCode(type, CoapCode.empty);

  /// Create a new acknowledgment for the specified message.
  /// Returns the acknowledgment.
  // ignore: prefer_constructors_over_static_methods
  static CoapEmptyMessage newACK(CoapMessage message) {
    final CoapEmptyMessage ack = CoapEmptyMessage(CoapMessageType.ack);
    ack.id = message.id;
    ack.token = CoapConstants.emptyToken;
    ack.destination = message.source;
    return ack;
  }

  /// Create a new reset message for the specified message.
  /// Return the reset.
  // ignore: prefer_constructors_over_static_methods
  static CoapEmptyMessage newRST(CoapMessage message) {
    final CoapEmptyMessage rst = CoapEmptyMessage(CoapMessageType.rst);
    rst.id = message.id;
    rst.token = CoapConstants.emptyToken;
    rst.destination = message.source;
    return rst;
  }

  /// Create a new empty message confirmable for the specified message.
  /// Return the empty
  // ignore: prefer_constructors_over_static_methods
  static CoapEmptyMessage newCon(CoapMessage message) {
    final CoapEmptyMessage ep = CoapEmptyMessage(CoapMessageType.con);
    ep.token = CoapConstants.emptyToken;
    ep.destination = message.source;
    return ep;
  }
}
