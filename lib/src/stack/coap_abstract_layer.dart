/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// A partial implementation of a layer.
class CoapAbstractLayer implements CoapILayer {
  CoapIExecutor executor;

  void sendRequest(
      CoapINextLayer nextLayer, CoapExchange exchange, CoapRequest request) {
    nextLayer.sendRequest(exchange, request);
  }

  void sendResponse(
      CoapINextLayer nextLayer, CoapExchange exchange, CoapResponse response) {
    nextLayer.sendResponse(exchange, response);
  }

  void sendEmptyMessage(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapEmptyMessage message) {
    nextLayer.sendEmptyMessage(exchange, message);
  }

  void receiveRequest(
      CoapINextLayer nextLayer, CoapExchange exchange, CoapRequest request) {
    nextLayer.receiveRequest(exchange, request);
  }

  void receiveResponse(
      CoapINextLayer nextLayer, CoapExchange exchange, CoapResponse response) {
    nextLayer.receiveResponse(exchange, response);
  }

  void receiveEmptyMessage(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapEmptyMessage message) {
    nextLayer.receiveEmptyMessage(exchange, message);
  }
}
