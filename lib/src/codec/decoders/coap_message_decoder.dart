/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

import 'package:typed_data/typed_data.dart';

import '../../coap_code.dart';
import '../../coap_constants.dart';
import '../../coap_empty_message.dart';
import '../../coap_message.dart';
import '../../coap_message_type.dart';
import '../../coap_request.dart';
import '../../coap_response.dart';
import '../coap_imessage_decoder.dart';
import '../datagram/coap_datagram_reader.dart';

/// Base class for message encoders.
abstract class CoapMessageDecoder implements CoapIMessageDecoder {
  /// Instantiates.
  CoapMessageDecoder(final Uint8Buffer data)
      : reader = CoapDatagramReader(data);

  /// The bytes reader
  final CoapDatagramReader reader;

  /// The type of the decoding message
  int get type;

  /// The code of the decoding message
  int get code;

  @override
  bool get isReply =>
      type == CoapMessageType.ack || type == CoapMessageType.rst;

  @override
  bool get isRequest =>
      code >= CoapConstants.requestCodeLowerBound &&
      code <= CoapConstants.requestCodeUpperBound;

  @override
  bool get isResponse =>
      code >= CoapConstants.responseCodeLowerBound &&
      code <= CoapConstants.responseCodeUpperBound;

  @override
  bool get isEmpty => code == CoapCode.empty;

  @override
  CoapRequest? decodeRequest() {
    if (isRequest) {
      final request = CoapRequest(code)
        ..type = type
        ..id = id;
      parseMessage(request);
      return request;
    }
    return null;
  }

  @override
  CoapResponse? decodeResponse() {
    if (isResponse) {
      final response = CoapResponse(code)
        ..type = type
        ..id = id;
      parseMessage(response);
      return response;
    }
    return null;
  }

  @override
  CoapEmptyMessage? decodeEmptyMessage() {
    if (!isResponse && !isRequest) {
      final message = CoapEmptyMessage(code)
        ..type = type
        ..id = id;
      parseMessage(message);
      return message;
    }
    return null;
  }

  @override
  CoapMessage? decodeMessage() {
    if (isRequest) {
      return decodeRequest();
    } else if (isResponse) {
      return decodeResponse();
    } else if (isEmpty) {
      return decodeEmptyMessage();
    } else {
      return null;
    }
  }

  /// Reads protocol headers.
  void readProtocol();

  /// Parses the rest data other than protocol headers into the given message.
  void parseMessage(final CoapMessage message);
}
