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
import 'coap_ilayer.dart';

/// A partial implementation of a layer.
class CoapAbstractLayer implements CoapILayer {
  @override
  void sendRequest(
    final CoapINextLayer nextLayer,
    final CoapExchange initialExchange,
    final CoapRequest request,
  ) {
    nextLayer.sendRequest(initialExchange, request);
  }

  @override
  void sendResponse(
    final CoapINextLayer nextLayer,
    final CoapExchange initialExchange,
    final CoapResponse response,
  ) {
    nextLayer.sendResponse(initialExchange, response);
  }

  @override
  void sendEmptyMessage(
    final CoapINextLayer nextLayer,
    final CoapExchange initialExchange,
    final CoapEmptyMessage message,
  ) {
    nextLayer.sendEmptyMessage(initialExchange, message);
  }

  @override
  void receiveRequest(
    final CoapINextLayer nextLayer,
    final CoapExchange initialExchange,
    final CoapRequest request,
  ) {
    nextLayer.receiveRequest(initialExchange, request);
  }

  @override
  void receiveResponse(
    final CoapINextLayer nextLayer,
    final CoapExchange initialExchange,
    final CoapResponse response,
  ) {
    nextLayer.receiveResponse(initialExchange, response);
  }

  @override
  void receiveEmptyMessage(
    final CoapINextLayer nextLayer,
    final CoapExchange initialExchange,
    final CoapEmptyMessage message,
  ) {
    nextLayer.receiveEmptyMessage(initialExchange, message);
  }
}
