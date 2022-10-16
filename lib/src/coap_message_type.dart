/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/05/2017
 * Copyright :  S.Hamblett
 */

import 'dart:collection';

/// Types of CoAP messages.
enum CoapMessageType {
  /// Confirmable messages require an acknowledgement.
  con(0, 'Confirmable'),

  /// Non-Confirmable messages do not require an acknowledgement.
  non(1, 'Non-Confirmable'),

  /// Acknowledgement messages acknowledge a specific confirmable message.
  ack(2, 'Acknowledgement'),

  /// Reset messages indicate that a specific confirmable message was received,
  /// but some context is missing to properly process it.
  rst(3, 'Reset');

  const CoapMessageType(this.code, this.description);

  final int code;

  final String description;

  /// Message type bit length
  static const int bitLength = 2;

  static final _registry = HashMap.fromEntries(
    values.map((final value) => MapEntry(value.code, value)),
  );

  static CoapMessageType? decode(final int code) => _registry[code];

  static CoapMessageType requestType({required final bool confirmable}) =>
      confirmable ? con : non;

  @override
  String toString() => 'Message type $code: $description';
}
