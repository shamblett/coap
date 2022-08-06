/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2018
 * Copyright :  S.Hamblett
 */

import '../coap_empty_message.dart';
import '../coap_option_type.dart';
import '../coap_request.dart';
import '../coap_response.dart';
import '../event/coap_event_bus.dart';
import '../net/coap_exchange.dart';
import '../net/coap_multicast_exchange.dart';
import 'coap_abstract_layer.dart';
import 'coap_chain.dart';
import 'coap_ilayer.dart';

/// The next processing layer
class CoapNextLayer implements CoapINextLayer {
  /// Construction
  CoapNextLayer(this._entry);

  final CoapEntry<dynamic, dynamic> _entry;

  @override
  void sendRequest(final CoapExchange? exchange, final CoapRequest request) {
    _entry.nextEntry!.filter
        .sendRequest(_entry.nextEntry!.nextFilter, exchange, request);
  }

  @override
  void sendResponse(final CoapExchange exchange, final CoapResponse? response) {
    _entry.nextEntry!.filter
        .sendResponse(_entry.nextEntry!.nextFilter, exchange, response);
  }

  @override
  void sendEmptyMessage(
    final CoapExchange exchange,
    final CoapEmptyMessage message,
  ) {
    _entry.nextEntry!.filter
        .sendEmptyMessage(_entry.nextEntry!.nextFilter, exchange, message);
  }

  @override
  void receiveRequest(final CoapExchange exchange, final CoapRequest request) {
    _entry.prevEntry!.filter
        .receiveRequest(_entry.prevEntry!.nextFilter, exchange, request);
  }

  @override
  void receiveResponse(
    final CoapExchange exchange,
    final CoapResponse response,
  ) {
    _entry.prevEntry!.filter
        .receiveResponse(_entry.prevEntry!.nextFilter, exchange, response);
  }

  @override
  void receiveEmptyMessage(
    final CoapExchange exchange,
    final CoapEmptyMessage message,
  ) {
    _entry.prevEntry!.filter
        .receiveEmptyMessage(_entry.prevEntry!.nextFilter, exchange, message);
  }
}

/// Top layer
class CoapStackTopLayer extends CoapAbstractLayer {
  @override
  void sendRequest(
    final CoapINextLayer nextLayer,
    final CoapExchange? initialExchange,
    final CoapRequest request,
  ) {
    var exchange = initialExchange;

    if (exchange == null) {
      if (request.isMulticast) {
        exchange = CoapMulticastExchange(
          request,
          CoapOrigin.local,
          namespace: request.eventBus!.namespace,
        );
      } else {
        exchange = CoapExchange(
          request,
          CoapOrigin.local,
          namespace: request.eventBus!.namespace,
        );
      }
      exchange.endpoint = request.endpoint;
    }
    exchange.request = request;
    super.sendRequest(nextLayer, exchange, request);
  }

  @override
  void sendResponse(
    final CoapINextLayer nextLayer,
    final CoapExchange initialExchange,
    final CoapResponse response,
  ) {
    initialExchange.response = response;
    super.sendResponse(nextLayer, initialExchange, response);
  }

  @override
  void receiveRequest(
    final CoapINextLayer nextLayer,
    final CoapExchange initialExchange,
    final CoapRequest request,
  ) {
    // If there is no BlockwiseLayer we still have to set it
    initialExchange.request ??= request;
  }

  @override
  void receiveResponse(
    final CoapINextLayer nextLayer,
    final CoapExchange initialExchange,
    final CoapResponse response,
  ) {
    if (!response.hasOption(OptionType.observe) &&
        initialExchange is! CoapMulticastExchange) {
      initialExchange.complete = true;
    }

    if (initialExchange.originalMulticastRequest != null) {
      // Track block2 responses across exchanges
      response.multicastToken = initialExchange.originalMulticastRequest!.token;
    }

    // block2 requests only have token set on their blocks
    initialExchange.request!.token ??= response.token;

    initialExchange.fireRespond(response);
  }

  @override
  void receiveEmptyMessage(
    final CoapINextLayer nextLayer,
    final CoapExchange initialExchange,
    final CoapEmptyMessage message,
  ) {
    // When empty messages reach the top of the CoAP stack we can ignore them.
  }
}

/// Bottom layer
class CoapStackBottomLayer extends CoapAbstractLayer {
  @override
  void sendRequest(
    final CoapINextLayer nextLayer,
    final CoapExchange? initialExchange,
    final CoapRequest request,
  ) {
    initialExchange?.outbox!.sendRequest(initialExchange, request);
  }

  @override
  void sendResponse(
    final CoapINextLayer nextLayer,
    final CoapExchange initialExchange,
    final CoapResponse response,
  ) {
    initialExchange.outbox!.sendResponse(initialExchange, response);
  }

  @override
  void sendEmptyMessage(
    final CoapINextLayer nextLayer,
    final CoapExchange initialExchange,
    final CoapEmptyMessage message,
  ) {
    initialExchange.outbox!.sendEmptyMessage(initialExchange, message);
  }
}

/// Stack of layers.
class CoapLayerStack
    extends CoapChain<CoapLayerStack, CoapILayer, CoapINextLayer> {
  /// Instantiates.
  CoapLayerStack()
      : super.filterFactory(
          (final e) => CoapNextLayer(e as CoapEntry<dynamic, dynamic>),
          CoapStackTopLayer.new,
          CoapStackBottomLayer.new,
        );

  /// Sends a request into the layer stack.
  void sendRequest(final CoapRequest request) {
    head!.filter.sendRequest(head!.nextFilter, null, request);
  }

  /// Sends a response into the layer stack.
  void sendResponse(final CoapExchange exchange, final CoapResponse? response) {
    head!.filter.sendResponse(head!.nextFilter, exchange, response);
  }

  /// Sends an empty message into the layer stack.
  void sendEmptyMessage(
    final CoapExchange exchange,
    final CoapEmptyMessage message,
  ) {
    head!.filter.sendEmptyMessage(head!.nextFilter, exchange, message);
  }

  /// Receives a request into the layer stack.
  void receiveRequest(final CoapExchange exchange, final CoapRequest? request) {
    tail!.filter.receiveRequest(tail!.nextFilter, exchange, request);
  }

  /// Receives a response into the layer stack.
  void receiveResponse(
    final CoapExchange exchange,
    final CoapResponse response,
  ) {
    tail!.filter.receiveResponse(tail!.nextFilter, exchange, response);
  }

  /// Receives an empty message into the layer stack.
  void receiveEmptyMessage(
    final CoapExchange exchange,
    final CoapEmptyMessage message,
  ) {
    tail!.filter.receiveEmptyMessage(tail!.nextFilter, exchange, message);
  }
}
