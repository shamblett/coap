/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Base class for message encoders.
abstract class CoapMessageDecoder implements CoapIMessageDecoder {
  /// Instantiates.
  CoapMessageDecoder(typed.Uint8Buffer data) {
    _reader = CoapDatagramReader(data);
  }

  /// The bytes reader
  CoapDatagramReader _reader;

  /// The version of the decoding message
  int _version;

  @override
  int get version => _version;

  /// The type of the decoding message
  int _type;

  /// The length of token
  int _tokenLength;

  /// The code of the decoding message
  int _code;

  /// The id of the decoding message
  int _id;

  @override
  int get id => _id;

  @override
  bool get isReply =>
      _type == CoapMessageType.ack || _type == CoapMessageType.rst;

  @override
  bool get isRequest =>
      _code >= CoapConstants.requestCodeLowerBound &&
      _code <= CoapConstants.requestCodeUpperBound;

  @override
  bool get isResponse =>
      _code >= CoapConstants.responseCodeLowerBound &&
      _code <= CoapConstants.responseCodeUpperBound;

  @override
  bool get isEmpty => _code == CoapCode.empty;

  @override
  CoapRequest decodeRequest() {
    if (isRequest) {
      final request = CoapRequest.withType(_code);
      request.type = _type;
      request.id = _id;
      parseMessage(request);
      return request;
    }

    return null;
  }

  @override
  CoapResponse decodeResponse() {
    if (isResponse) {
      final response = CoapResponse(_code);
      response.type = _type;
      response.id = _id;
      parseMessage(response);
      return response;
    }

    return null;
  }

  @override
  CoapEmptyMessage decodeEmptyMessage() {
    if ((!isResponse) && (!isRequest)) {
      final message = CoapEmptyMessage(_code);
      message.type = _type;
      message.id = _id;
      parseMessage(message);
      return message;
    }

    return null;
  }

  @override
  CoapMessage decodeMessage() {
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
  void parseMessage(CoapMessage message);
}
