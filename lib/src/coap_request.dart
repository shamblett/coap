/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Event classes
class CoapRespondEvent {}

class CoapRespondingEvent {}

class CoapReregisteringEvent {}

/// This class describes the functionality of a CoAP Request as
/// a subclass of a CoAP Message. It provides:
/// 1. operations to answer a request by a response using respond()
/// 2. different ways to handle incoming responses: receiveResponse() or Response event
class CoapRequest extends CoapMessage {
  /// Initializes a request message.
  CoapRequest(int code) : this.isConfirmable(code, true);

  /// Initializes a request message.
  /// True if the request is Confirmable
  CoapRequest.isConfirmable(int code, bool confirmable)
      : super.withCode(
      confirmable ? CoapMessageType.con : CoapMessageType.non, code) {
    _method = code;
  }

  int _method;
  bool _multicast;
  Uri _uri;
  CoapResponse _currentResponse;
  CoapIEndPoint _endPoint;
  Object _sync;
}
