/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

abstract class CoapIMatcher {
  void clear();

  void start();

  void stop();

  void sendRequest(CoapExchange exchange, CoapRequest request);

  void sendResponse(CoapExchange exchange, CoapResponse response);

  void sendEmptyMessage(CoapExchange exchange, CoapEmptyMessage message);

  CoapExchange receiveRequest(CoapRequest request);

  CoapExchange receiveResponse(CoapResponse response);

  CoapExchange receiveEmptyMessage(CoapEmptyMessage message);
}
