/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

// ignore_for_file: omit_local_variable_types
// ignore_for_file: unnecessary_final
// ignore_for_file: cascade_invocations
// ignore_for_file: avoid_print
// ignore_for_file: avoid_types_on_closure_parameters
// ignore_for_file: avoid_returning_this
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes
// ignore_for_file: prefer_null_aware_operators
// ignore_for_file: avoid_annotating_with_dynamic

/// Base class for message encoders.
abstract class CoapMessageEncoder implements CoapIMessageEncoder {
  @override
  typed.Uint8Buffer encodeRequest(CoapRequest request) {
    final CoapDatagramWriter writer = CoapDatagramWriter();
    serialize(writer, request, request.code);
    return writer.toByteArray();
  }

  @override
  typed.Uint8Buffer encodeResponse(CoapResponse response) {
    final CoapDatagramWriter writer = CoapDatagramWriter();
    serialize(writer, response, response.code);
    return writer.toByteArray();
  }

  @override
  typed.Uint8Buffer encodeEmpty(CoapEmptyMessage message) {
    final CoapDatagramWriter writer = CoapDatagramWriter();
    serialize(writer, message, CoapCode.empty);
    return writer.toByteArray();
  }

  @override
  typed.Uint8Buffer encodeMessage(CoapMessage message) {
    if (message.isRequest) {
      return encodeRequest(message);
    } else if (message.isResponse) {
      return encodeResponse(message);
    } else if (message.isEmpty) {
      //A ping message is empty, but it is a request message so check for this
      if (message is CoapRequest) {
        return encodeRequest(message);
      } else {
        return encodeEmpty(message);
      }
    } else {
      return null;
    }
  }

  /// Serializes a message.
  void serialize(CoapDatagramWriter writer, CoapMessage message, int code);
}
