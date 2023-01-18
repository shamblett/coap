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
  BaseLayer? _nextLayer;

  void addLayer(final BaseLayer layer) {
    final nextLayer = _nextLayer;
    if (nextLayer == null) {
      _nextLayer = layer;
    } else {
      nextLayer.addLayer(layer);
    }
  }

  void sendRequest(
    final CoapExchange initialExchange,
    final CoapRequest request,
  ) {
    _nextLayer?.sendRequest(initialExchange, request);
  }

  void sendResponse(
    final CoapExchange initialExchange,
    final CoapResponse response,
  ) {
    _nextLayer?.sendResponse(initialExchange, response);
  }

  void sendEmptyMessage(
    final CoapExchange initialExchange,
    final CoapEmptyMessage message,
  ) {
    _nextLayer?.sendEmptyMessage(initialExchange, message);
  }

  void receiveRequest(
    final CoapExchange initialExchange,
    final CoapRequest request,
  ) {
    _nextLayer?.receiveRequest(initialExchange, request);
  }

  void receiveResponse(
    final CoapExchange initialExchange,
    final CoapResponse response,
  ) {
    _nextLayer?.receiveResponse(initialExchange, response);
  }

  void receiveEmptyMessage(
    final CoapExchange initialExchange,
    final CoapEmptyMessage message,
  ) {
    _nextLayer?.receiveEmptyMessage(initialExchange, message);
  }
}
