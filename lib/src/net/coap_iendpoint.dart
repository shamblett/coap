/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Events
/// Occurs when a request is about to be sent.
class CoapSendingRequestEvent {
  /// Construction
  CoapSendingRequestEvent(this.request);

  /// The request
  CoapRequest request;
}

/// Occurs when a response is about to be sent.
class CoapSendingResponseEvent {
  /// Construction
  CoapSendingResponseEvent(this.response);

  /// The response
  CoapResponse response;
}

/// Occurs when a an empty message is about to be sent.
class CoapSendingEmptyMessageEvent {
  /// Construction
  CoapSendingEmptyMessageEvent(this.empty);

  /// The empty message
  CoapEmptyMessage empty;
}

/// Occurs when a request has been received.
class CoapReceivingRequestEvent {
  /// Construction
  CoapReceivingRequestEvent(this.request);

  /// The request
  CoapRequest request;
}

/// Occurs when a response has been received.
class CoapReceivingResponseEvent {
  /// Construction
  CoapReceivingResponseEvent(this.response);

  /// The response
  CoapResponse response;
}

/// Occurs when an empty message has been received.
class CoapReceivingEmptyMessageEvent {
  /// Construction
  CoapReceivingEmptyMessageEvent(this.empty);

  /// The empty message
  CoapEmptyMessage empty;
}

/// Represents a communication endpoint multiplexing CoAP message exchanges
/// between (potentially multiple) clients and servers.
abstract class CoapIEndPoint {
  /// Gets this endpoint's configuration.
  CoapConfig get config;

  /// Gets the local internetAddress this endpoint is associated with.
  InternetAddress get localEndpoint;

  /// Gets or sets the message deliverer.
  CoapIMessageDeliverer deliverer;

  /// Gets the outbox.
  CoapIOutbox get outbox;

  /// Starts this endpoint and all its components.
  void start();

  /// Stops this endpoint and all its components
  void stop();

  /// Clears this endpoint
  void clear();

  /// Sends the specified request.
  void sendEpRequest(CoapRequest request);

  /// Sends the specified response.
  void sendEpResponse(CoapExchange exchange, CoapResponse response);

  /// Sends the specified empty message.
  void sendEpEmptyMessage(CoapExchange exchange, CoapEmptyMessage message);
}
