/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

import 'coap_code.dart';
import 'coap_constants.dart';
import 'coap_message.dart';
import 'coap_message_type.dart';

/// Represents an empty CoAP message. An empty message has either
/// the MessageType ACK or RST.
class CoapEmptyMessage extends CoapMessage {
  /// Instantiates a new empty message.
  CoapEmptyMessage(int type) : super(type: type, code: CoapCode.empty);

  /// Create a new acknowledgment for the specified message.
  /// Returns the acknowledgment.
  static CoapEmptyMessage newACK(CoapMessage message) {
    final ack = CoapEmptyMessage(CoapMessageType.ack);
    ack.id = message.id;
    ack.token = CoapConstants.emptyToken;
    ack.destination = message.source;
    return ack;
  }

  /// Create a new reset message for the specified message.
  /// Return the reset.
  static CoapEmptyMessage newRST(CoapMessage message) {
    final rst = CoapEmptyMessage(CoapMessageType.rst);
    rst.id = message.id;
    rst.token = CoapConstants.emptyToken;
    rst.destination = message.source;
    return rst;
  }

  /// Create a new empty message confirmable for the specified message.
  /// Return the empty
  static CoapEmptyMessage newCon(CoapMessage message) {
    final ep = CoapEmptyMessage(CoapMessageType.con);
    ep.token = CoapConstants.emptyToken;
    ep.destination = message.source;
    return ep;
  }
}
