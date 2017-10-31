/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Events
/// Occurs when a request is about to be sent.

class CoapSendingRequestEvent {}

/// Occurs when a response is about to be sent.
class CoapSendingResponseEvent {}

/// Occurs when a an empty message is about to be sent.
class CoapSendingEmptyMessageEvent {}

/// Occurs when a request request has been received.
class CoapReceivingRequestEvent {}

/// Occurs when a response has been received.
class CoapReceivingResponseEvent {}

/// Occurs when an empty message has been received.
class CoapReceivingEmptyMessageEvent {}

/// Represents a communication endpoint multiplexing CoAP message exchanges
/// between (potentially multiple) clients and servers.
abstract class CoapIEndPoint extends Object with events.EventEmitter {
  /// Gets this endpoint's configuration.
  CoapConfig get config;

  /// Gets the local internetAddress this endpoint is associated with.
  InternetAddress get localEndPoint;

  /// Checks if the endpoint has started.
  bool get running;

  /// Gets or sets the message deliverer.
  CoapIMessageDeliverer messageDeliverer;

  /// Gets the outbox.
  CoapIOutbox get outbox;

  /// Starts this endpoint and all its components.
  void start();

  /// Stops this endpoint and all its components
  void stop();

  /// Clears this endpoint
  void clear();

  /// Sends the specified request.
  void sendRequest(CoapRequest request);

  /// Sends the specified response.
  void sendResponse(CoapExchange exchange, CoapResponse response);

  /// Sends the specified empty message.
  void sendEmptyMessage(CoapExchange exchange, CoapEmptyMessage message);
}
