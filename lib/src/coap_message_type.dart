/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/05/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Types of CoAP messages.
class CoapMessageType {
  /// Unknown type.
  static const int unknown = -1;

  /// Confirmable messages require an acknowledgement.
  static const int con = 0;

  /// Non-Confirmable messages do not require an acknowledgement.
  static const int non = 1;

  /// Acknowledgement messages acknowledge a specific confirmable message.
  static const int ack = 2;

  /// Reset messages indicate that a specific confirmable message was received,
  /// but some context is missing to properly process it.
  static const int rst = 3;
}
