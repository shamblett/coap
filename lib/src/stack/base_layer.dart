/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/05/2018
 * Copyright :  S.Hamblett
 */

import '../coap_empty_message.dart';
import '../coap_request.dart';
import '../coap_response.dart';
import '../net/exchange.dart';

/// A partial implementation of a layer.
abstract class BaseLayer {
  BaseLayer([this.nextLayer]);

  BaseLayer? nextLayer;

  void sendRequest(
    final CoapExchange initialExchange,
    final CoapRequest request,
  ) {
    nextLayer?.sendRequest(initialExchange, request);
  }

  void sendResponse(
    final CoapExchange initialExchange,
    final CoapResponse response,
  ) {
    nextLayer?.sendResponse(initialExchange, response);
  }

  void sendEmptyMessage(
    final CoapExchange initialExchange,
    final CoapEmptyMessage message,
  ) {
    nextLayer?.sendEmptyMessage(initialExchange, message);
  }

  void receiveRequest(
    final CoapExchange initialExchange,
    final CoapRequest request,
  ) {
    nextLayer?.receiveRequest(initialExchange, request);
  }

  void receiveResponse(
    final CoapExchange initialExchange,
    final CoapResponse response,
  ) {
    nextLayer?.receiveResponse(initialExchange, response);
  }

  void receiveEmptyMessage(
    final CoapExchange initialExchange,
    final CoapEmptyMessage message,
  ) {
    nextLayer?.receiveEmptyMessage(initialExchange, message);
  }
}
