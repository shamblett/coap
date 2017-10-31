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
}