/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Represent a next layer in the stack.
abstract class CoapINextLayer {
  /// Sends a request to next layer.
  void sendRequest(CoapExchange? exchange, CoapRequest request);

  /// Sends a response to next layer.
  void sendResponse(CoapExchange exchange, CoapResponse? response);

  /// Sends an empty message to next layer.
  void sendEmptyMessage(CoapExchange exchange, CoapEmptyMessage message);

  /// Receives a request to next layer.
  void receiveRequest(CoapExchange exchange, CoapRequest request);

  /// Receives a response to next layer.
  void receiveResponse(CoapExchange exchange, CoapResponse response);

  /// Receives an empty message to next layer.
  void receiveEmptyMessage(CoapExchange exchange, CoapEmptyMessage message);
}

/// Represents a layer in the stack.
abstract class CoapILayer {
  /// Gets or set the executor to schedule tasks.
  CoapIExecutor? executor;

  /// Filters a request sending event.
  void sendRequest(
      CoapINextLayer nextLayer, CoapExchange? exchange, CoapRequest request);

  /// Filters a response sending event.
  void sendResponse(
      CoapINextLayer nextLayer, CoapExchange exchange, CoapResponse response);

  /// Filters an empty message sending event.
  void sendEmptyMessage(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapEmptyMessage message);

  /// Filters a request receiving event.
  void receiveRequest(
      CoapINextLayer nextLayer, CoapExchange exchange, CoapRequest request);

  /// Filters a response receiving event.
  void receiveResponse(
      CoapINextLayer nextLayer, CoapExchange exchange, CoapResponse response);

  /// Filters an empty message receiving event.
  void receiveEmptyMessage(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapEmptyMessage message);
}
