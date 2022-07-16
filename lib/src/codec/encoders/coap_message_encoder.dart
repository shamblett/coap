/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

import 'package:typed_data/typed_data.dart';

import '../../coap_code.dart';
import '../../coap_empty_message.dart';
import '../../coap_message.dart';
import '../../coap_request.dart';
import '../../coap_response.dart';
import '../coap_imessage_encoder.dart';
import '../datagram/coap_datagram_writer.dart';

/// Base class for message encoders.
abstract class CoapMessageEncoder implements CoapIMessageEncoder {
  @override
  Uint8Buffer encodeRequest(final CoapRequest request) {
    final writer = CoapDatagramWriter();
    serialize(writer, request, request.code.code);
    return writer.toByteArray();
  }

  @override
  Uint8Buffer encodeResponse(final CoapResponse response) {
    final writer = CoapDatagramWriter();
    serialize(writer, response, response.code.code);
    return writer.toByteArray();
  }

  @override
  Uint8Buffer encodeEmpty(final CoapEmptyMessage message) {
    final writer = CoapDatagramWriter();
    serialize(writer, message, CoapCode.empty.code);
    return writer.toByteArray();
  }

  @override
  Uint8Buffer? encodeMessage(final CoapMessage message) {
    if (message.isRequest) {
      return encodeRequest(message as CoapRequest);
    } else if (message.isResponse) {
      return encodeResponse(message as CoapResponse);
    } else if (message.isEmpty) {
      //A ping message is empty, but it is a request message so check for this
      if (message is CoapRequest) {
        return encodeRequest(message);
      } else {
        return encodeEmpty(message as CoapEmptyMessage);
      }
    } else {
      return null;
    }
  }

  /// Serializes a message.
  void serialize(
    final CoapDatagramWriter writer,
    final CoapMessage message,
    final int code,
  );
}
