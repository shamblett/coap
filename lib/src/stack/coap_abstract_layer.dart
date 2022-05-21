/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/05/2018
 * Copyright :  S.Hamblett
 */

import '../coap_empty_message.dart';
import '../coap_request.dart';
import '../coap_response.dart';
import '../net/coap_exchange.dart';
import '../tasks/coap_iexecutor.dart';
import 'coap_ilayer.dart';

/// A partial implementation of a layer.
class CoapAbstractLayer implements CoapILayer {
  @override
  CoapIExecutor? executor;

  @override
  void sendRequest(
      CoapINextLayer nextLayer, CoapExchange? exchange, CoapRequest request) {
    nextLayer.sendRequest(exchange, request);
  }

  @override
  void sendResponse(
      CoapINextLayer nextLayer, CoapExchange exchange, CoapResponse response) {
    nextLayer.sendResponse(exchange, response);
  }

  @override
  void sendEmptyMessage(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapEmptyMessage message) {
    nextLayer.sendEmptyMessage(exchange, message);
  }

  @override
  void receiveRequest(
      CoapINextLayer nextLayer, CoapExchange exchange, CoapRequest request) {
    nextLayer.receiveRequest(exchange, request);
  }

  @override
  void receiveResponse(
      CoapINextLayer nextLayer, CoapExchange exchange, CoapResponse response) {
    nextLayer.receiveResponse(exchange, response);
  }

  @override
  void receiveEmptyMessage(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapEmptyMessage message) {
    nextLayer.receiveEmptyMessage(exchange, message);
  }
}
