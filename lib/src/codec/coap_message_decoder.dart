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
    _reader = new CoapDatagramReader(data);
  }

  /// The bytes reader
  CoapDatagramReader _reader;

  /// The version of the decoding message
  int _version;

  int get version => _version;

  /// The type of the decoding message
  int _type;

  /// The length of token
  int _tokenLength;

  /// The code of the decoding message
  int _code;

  /// The id of the decoding message
  int _id;

  int get id => _id;

  bool get isReply =>
      _type == CoapMessageType.ack || _type == CoapMessageType.rst;

  bool get isRequest =>
      _code >= CoapConstants.requestCodeLowerBound &&
      _code <= CoapConstants.requestCodeUpperBound;

  bool get isResponse =>
      _code >= CoapConstants.responseCodeLowerBound &&
      _code <= CoapConstants.responseCodeUpperBound;

  bool get isEmpty => _code == CoapCode.empty;

  CoapRequest decodeRequest() {
    if (isRequest) {
      final CoapRequest request = new CoapRequest(_code);
      request.type = _type;
      request.id = _id;
      parseMessage(request);
      return request;
    }

    return null;
  }

  CoapResponse decodeResponse() {
    if (isResponse) {
      final CoapResponse response = new CoapResponse(_code);
      response.type = _type;
      response.id = _id;
      parseMessage(response);
      return response;
    }

    return null;
  }

  CoapEmptyMessage decodeEmptyMessage() {
    if ((!isResponse) && (!isRequest)) {
      final CoapEmptyMessage message = new CoapEmptyMessage(_code);
      message.type = _type;
      message.id = _id;
      parseMessage(message);
      return message;
    }

    return null;
  }

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
