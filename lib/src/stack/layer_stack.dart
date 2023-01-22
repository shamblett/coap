/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/06/2018
 * Copyright :  S.Hamblett
 */

import 'package:meta/meta.dart';

import '../coap_config.dart';
import '../coap_empty_message.dart';
import '../coap_request.dart';
import '../coap_response.dart';
import '../net/exchange.dart';
import 'layers/blockwise.dart';
import 'layers/bottom.dart';
import 'layers/observe.dart';
import 'layers/reliability.dart';
import 'layers/token.dart';
import 'layers/top.dart';

/// Builds up the stack of CoAP layers
/// that process the CoAP protocol.
@immutable
class LayerStack {
  /// Instantiates.
  LayerStack(final DefaultCoapConfig config) {
    _topLayer
      ..addLayer(ReliabilityLayer(config))
      ..addLayer(TokenLayer())
      ..addLayer(BlockwiseLayer(config))
      ..addLayer(ObserveLayer(config))
      ..addLayer(BottomLayer());
  }

  final _topLayer = CoapStackTopLayer();

  /// Sends a request into the layer stack.
  void sendRequest(final CoapRequest request) {
    _topLayer.sendRequest(null, request);
  }

  /// Sends a response into the layer stack.
  void sendResponse(final CoapExchange exchange, final CoapResponse response) {
    _topLayer.sendResponse(exchange, response);
  }

  /// Sends an empty message into the layer stack.
  void sendEmptyMessage(
    final CoapExchange exchange,
    final CoapEmptyMessage message,
  ) {
    _topLayer.sendEmptyMessage(exchange, message);
  }

  /// Receives a request into the layer stack.
  void receiveRequest(final CoapExchange exchange, final CoapRequest request) {
    _topLayer.receiveRequest(exchange, request);
  }

  /// Receives a response into the layer stack.
  void receiveResponse(
    final CoapExchange exchange,
    final CoapResponse response,
  ) {
    _topLayer.receiveResponse(exchange, response);
  }

  /// Receives an empty message into the layer stack.
  void receiveEmptyMessage(
    final CoapExchange exchange,
    final CoapEmptyMessage message,
  ) {
    _topLayer.receiveEmptyMessage(exchange, message);
  }
}
