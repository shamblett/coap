/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

import 'package:typed_data/typed_data.dart';

import 'coap_code.dart';
import 'coap_constants.dart';
import 'coap_message.dart';
import 'coap_message_type.dart';
import 'option/option.dart';

/// Represents an empty CoAP message. An empty message has either
/// the MessageType ACK or RST.
class CoapEmptyMessage extends CoapMessage {
  /// Instantiates a new empty message.
  CoapEmptyMessage(final CoapMessageType type)
      : super(RequestMethod.empty.coapCode, type);

  /// Create a new acknowledgment for the specified message.
  /// Returns the acknowledgment.
  factory CoapEmptyMessage.newACK(final CoapMessage message) =>
      CoapEmptyMessage(CoapMessageType.ack)
        ..id = message.id
        ..token = CoapConstants.emptyToken
        ..destination = message.source;

  /// Create a new reset message for the specified message.
  /// Return the reset.
  factory CoapEmptyMessage.newRST(final CoapMessage message) =>
      CoapEmptyMessage(CoapMessageType.rst)
        ..id = message.id
        ..token = CoapConstants.emptyToken
        ..destination = message.source;

  /// Create a new empty message confirmable for the specified message.
  /// Return the empty
  factory CoapEmptyMessage.newCon(final CoapMessage message) =>
      CoapEmptyMessage(CoapMessageType.con)
        ..token = CoapConstants.emptyToken
        ..destination = message.source;

  CoapEmptyMessage.fromParsed({
    required final CoapMessageType type,
    required final int id,
    required final Uint8Buffer token,
    required final List<Option<Object?>> options,
    required final Uint8Buffer? payload,
    required final bool hasUnknownCriticalOption,
    required final bool hasFormatError,
  }) : super.fromParsed(
          RequestMethod.empty.coapCode,
          type,
          id: id,
          token: token,
          options: options,
          hasUnknownCriticalOption: hasUnknownCriticalOption,
          hasFormatError: hasFormatError,
          payload: payload,
        );
}
