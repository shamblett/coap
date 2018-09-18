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
  CoapRequest request;

  CoapSendingRequestEvent(this.request);
}

/// Occurs when a response is about to be sent.
class CoapSendingResponseEvent {
  CoapResponse response;

  CoapSendingResponseEvent(this.response);
}

/// Occurs when a an empty message is about to be sent.
class CoapSendingEmptyMessageEvent {
  CoapEmptyMessage empty;

  CoapSendingEmptyMessageEvent(this.empty);
}

/// Occurs when a request request has been received.
class CoapReceivingRequestEvent {
  CoapRequest request;

  CoapReceivingRequestEvent(this.request);
}

/// Occurs when a response has been received.
class CoapReceivingResponseEvent {
  CoapResponse response;

  CoapReceivingResponseEvent(this.response);
}

/// Occurs when an empty message has been received.
class CoapReceivingEmptyMessageEvent {
  CoapEmptyMessage empty;

  CoapReceivingEmptyMessageEvent(this.empty);
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
