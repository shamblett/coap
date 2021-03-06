/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Interfca efor the Matcher class
abstract class CoapIMatcher {
  /// Clear
  void clear();

  /// Start
  void start();

  /// Stop
  void stop();

  /// Send a request
  void sendRequest(CoapExchange exchange, CoapRequest request);

  /// Send a response
  void sendResponse(CoapExchange exchange, CoapResponse? response);

  /// Send an empty message
  void sendEmptyMessage(CoapExchange exchange, CoapEmptyMessage message);

  /// Received request
  CoapExchange receiveRequest(CoapRequest? request);

  /// Received response
  CoapExchange? receiveResponse(CoapResponse response);

  /// Received empty message
  CoapExchange? receiveEmptyMessage(CoapEmptyMessage message);
}
