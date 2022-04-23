/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Interface for an Outbox
abstract class CoapIOutbox {
  /// Sends the specified request over the connector that the
  /// stack is connected to.
  void sendRequest(CoapExchange exchange, CoapRequest request);

  /// Sends the specified response over the connector that the
  /// stack is connected to.
  void sendResponse(CoapExchange exchange, CoapResponse response);

  /// Sends the specified empty message over the connector that the
  /// stack is connected to.
  void sendEmptyMessage(CoapExchange exchange, CoapEmptyMessage message);
}
