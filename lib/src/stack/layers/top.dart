import '../../coap_request.dart';
import '../../coap_response.dart';
import '../../event/coap_event_bus.dart';
import '../../net/exchange.dart';
import '../../net/multicast_exchange.dart';
import '../../option/coap_block_option.dart';
import '../../option/integer_option.dart';
import '../base_layer.dart';

/// Top layer
class CoapStackTopLayer extends BaseLayer {
  @override
  void sendRequest(
    final CoapExchange? initialExchange,
    final CoapRequest request,
  ) {
    final CoapExchange exchange;

    if (initialExchange == null) {
      final endpoint = request.endpoint!;
      exchange =
          request.isMulticast
              ? CoapMulticastExchange(
                request,
                CoapOrigin.local,
                endpoint,
                namespace: request.eventBus!.namespace,
              )
              : CoapExchange(
                request,
                CoapOrigin.local,
                endpoint,
                namespace: request.eventBus!.namespace,
              );
    } else {
      exchange = initialExchange;
    }
    exchange.request = request;
    super.sendRequest(exchange, request);
  }

  @override
  void sendResponse(
    final CoapExchange initialExchange,
    final CoapResponse response,
  ) {
    initialExchange.response = response;
    super.sendResponse(initialExchange, response);
  }

  @override
  void receiveRequest(
    final CoapExchange initialExchange,
    final CoapRequest request,
  ) {
    // If there is no BlockwiseLayer we still have to set it
    initialExchange.request = request;
  }

  @override
  void receiveResponse(
    final CoapExchange initialExchange,
    final CoapResponse response,
  ) {
    if (response.hasOption<Block2Option>() ||
        response.hasOption<Block1Option>()) {
      super.receiveResponse(initialExchange, response);
      return;
    }

    if (!response.hasOption<ObserveOption>() &&
        initialExchange is! CoapMulticastExchange) {
      initialExchange.complete = true;
    }

    final originalMulticastRequest = initialExchange.originalMulticastRequest;
    if (originalMulticastRequest != null) {
      // Track block2 responses across exchanges
      response.multicastToken = originalMulticastRequest.token;
    }

    initialExchange.fireRespond(response);
    super.receiveResponse(initialExchange, response);
  }
}
