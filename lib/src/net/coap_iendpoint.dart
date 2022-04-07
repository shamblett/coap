/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Events
/// Represents a communication endpoint multiplexing CoAP message exchanges
/// between (potentially multiple) clients and servers.
abstract class CoapIEndPoint {
  /// The endpoint's destination
  CoapInternetAddress? get destination;

  /// Gets this endpoint's configuration.
  DefaultCoapConfig? get config;

  /// The next message id to use
  int get nextMessageId;

  /// Gets the local internetAddress this endpoint is associated with.
  CoapInternetAddress? get localEndpoint;

  /// Gets or sets the message deliverer.
  CoapIMessageDeliverer? deliverer;

  /// Gets the outbox.
  CoapIOutbox get outbox;

  /// Starts this endpoint and all its components.
  Future<void> start();

  /// Stops this endpoint and all its components
  void stop();

  /// Clears this endpoint
  void clear();

  /// Sends the specified request.
  void sendEpRequest(CoapRequest request);

  /// Sends the specified response.
  void sendEpResponse(CoapExchange exchange, CoapResponse? response);

  /// Sends the specified empty message.
  void sendEpEmptyMessage(CoapExchange exchange, CoapEmptyMessage message);
}
