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
  int? get type;

  CoapMessageType? get _decodedType {
    final type_ = type;
    if (type_ == null) {
      return null;
    }
    return CoapMessageType.decode(type_);
  }

  /// The code of the decoding message
  int? get code;

  CoapCode? get _decodedCode {
    final code_ = code;
    if (code_ == null) {
      return null;
    }
    return CoapCode.decode(code_);
  }

  @override
  bool get isReply =>
      type == CoapMessageType.ack.code || type == CoapMessageType.rst.code;

  @override
  bool get isRequest => _decodedCode?.isRequest ?? false;

  @override
  bool get isResponse => _decodedCode?.isResponse ?? false;

  @override
  bool get isEmpty => _decodedCode?.isEmpty ?? false;

  @override
  CoapRequest? decodeRequest() {
    final decodedCode = _decodedCode;

    if (decodedCode != null && isRequest) {
      final request = CoapRequest(
        decodedCode,
        confirmable: type == CoapMessageType.con.code,
      )..id = id;
      parseMessage(request);
      return request;
    }
    return null;
  }

  @override
  CoapResponse? decodeResponse() {
    final decodedCode = _decodedCode;
    final coapMessageType = _decodedType;

    if (!isResponse || decodedCode == null || coapMessageType == null) {
      return null;
    }

    final response = CoapResponse(decodedCode, coapMessageType)..id = id;
    parseMessage(response);
    return response;
  }

  @override
  CoapEmptyMessage? decodeEmptyMessage() {
    final coapMessageType = _decodedType;
    if (coapMessageType == null || !isEmpty) {
      return null;
    }

    final message = CoapEmptyMessage(coapMessageType)..id = id;
    parseMessage(message);
    return message;
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
