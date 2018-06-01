/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

class CoapNextLayer implements CoapINextLayer {
  CoapEntry _entry;

  CoapNextLayer(CoapEntry entry) {
    _entry = entry;
  }

  void sendRequest(CoapExchange exchange, CoapRequest request) {
    _entry.nextEntry.filter
        .sendRequest(_entry.nextEntry.nextFilter, exchange, request);
  }

  void sendResponse(CoapExchange exchange, CoapResponse response) {
    _entry.nextEntry.filter
        .sendResponse(_entry.nextEntry.nextFilter, exchange, response);
  }

  void sendEmptyMessage(CoapExchange exchange, CoapEmptyMessage message) {
    _entry.nextEntry.filter
        .sendEmptyMessage(_entry.nextEntry.nextFilter, exchange, message);
  }

  void receiveRequest(CoapExchange exchange, CoapRequest request) {
    _entry.prevEntry.filter
        .receiveRequest(_entry.prevEntry.nextFilter, exchange, request);
  }

  void receiveResponse(CoapExchange exchange, CoapResponse response) {
    _entry.prevEntry.filter
        .receiveResponse(_entry.prevEntry.nextFilter, exchange, response);
  }

  void receiveEmptyMessage(CoapExchange exchange, CoapEmptyMessage message) {
    _entry.prevEntry.filter
        .receiveEmptyMessage(_entry.prevEntry.nextFilter, exchange, message);
  }
}

class CoapStackTopLayer extends CoapAbstractLayer {
  @override
  void sendRequest(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapRequest request) {
    final CoapExchange nexchange = exchange;
    if (exchange == null) {
      final nexchange = new CoapExchange(request, CoapOrigin.local);
      nexchange.endpoint = request.endPoint;
    }

    nexchange.request = request;
    super.sendRequest(nextLayer, nexchange, request);
  }

  @override
  void sendResponse(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapResponse response) {
    exchange.response = response;
    super.sendResponse(nextLayer, exchange, response);
  }

  @override
  void receiveRequest(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapRequest request) {
    // If there is no BlockwiseLayer we still have to set it
    if (exchange.request == null) {
      exchange.request = request;
    }
    if (exchange.deliverer != null) {
      exchange.deliverer.deliverRequest(exchange);
    }
  }

  @override
  void receiveResponse(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapResponse response) {
    if (!response.hasOption(optionTypeObserve)) {
      exchange.complete = true;
    }
    if (exchange.deliverer != null) {
      // Notify request that response has arrived
      exchange.deliverer.deliverResponse(exchange, response);
    }
  }

  @override
  void receiveEmptyMessage(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapEmptyMessage message) {
    // When empty messages reach the top of the CoAP stack we can ignore them.
  }
}

class CoapStackBottomLayer extends CoapAbstractLayer {
  @override
  void sendRequest(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapRequest request) {
    exchange.outbox.sendRequest(exchange, request);
  }

  @override
  void sendResponse(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapResponse response) {
    exchange.outbox.sendResponse(exchange, response);
  }

  @override
  void sendEmptyMessage(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapEmptyMessage message) {
    exchange.outbox.sendEmptyMessage(exchange, message);
  }
}

/// Stack of layers.
class CoapLayerStack
    extends CoapChain<CoapLayerStack, CoapILayer, CoapINextLayer> {
  /// Instantiates.
  CoapLayerStack()
      : super.filterFactory((e) => new CoapNextLayer(e),
          () => new CoapStackTopLayer(), () => new CoapStackBottomLayer());

  /// Sends a request into the layer stack.
  void sendRequest(CoapRequest request) {
    head.filter.sendRequest(head.nextFilter, null, request);
  }

  /// Sends a response into the layer stack.
  void sendResponse(CoapExchange exchange, CoapResponse response) {
    head.filter.sendResponse(head.nextFilter, exchange, response);
  }

  /// Sends an empty message into the layer stack.
  void sendEmptyMessage(CoapExchange exchange, CoapEmptyMessage message) {
    head.filter.sendEmptyMessage(head.nextFilter, exchange, message);
  }

  /// Receives a request into the layer stack.
  void receiveRequest(CoapExchange exchange, CoapRequest request) {
    tail.filter.receiveRequest(tail.nextFilter, exchange, request);
  }

  /// Receives a response into the layer stack.
  void receiveResponse(CoapExchange exchange, CoapResponse response) {
    tail.filter.receiveResponse(tail.nextFilter, exchange, response);
  }

  /// Receives an empty message into the layer stack.
  void receiveEmptyMessage(CoapExchange exchange, CoapEmptyMessage message) {
    tail.filter.receiveEmptyMessage(tail.nextFilter, exchange, message);
  }
}
