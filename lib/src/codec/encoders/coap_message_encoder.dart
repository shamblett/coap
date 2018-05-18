/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Base class for message encoders.
abstract class CoapMessageEncoder implements CoapIMessageEncoder {
  typed.Uint8Buffer encodeRequest(CoapRequest request) {
    final CoapDatagramWriter writer = new CoapDatagramWriter();
    serialize(writer, request, request.code);
    return writer.toByteArray();
  }

  typed.Uint8Buffer encodeResponse(CoapResponse response) {
    final CoapDatagramWriter writer = new CoapDatagramWriter();
    serialize(writer, response, response.code);
    return writer.toByteArray();
  }

  typed.Uint8Buffer encodeEmpty(CoapEmptyMessage message) {
    final CoapDatagramWriter writer = new CoapDatagramWriter();
    serialize(writer, message, CoapCode.empty);
    return writer.toByteArray();
  }

  typed.Uint8Buffer encodeMessage(CoapMessage message) {
    if (message.isRequest) {
      return encodeRequest(message as CoapRequest);
    } else if (message.isResponse) {
      return encodeResponse(message as CoapResponse);
    } else if (message is CoapEmptyMessage) {
      return encodeEmpty(message);
    } else {
      return null;
    }
  }

  /// Serializes a message.
  void serialize(CoapDatagramWriter writer, CoapMessage message, int code);
}
