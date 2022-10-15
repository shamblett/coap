import '../../coap_option_type.dart';
import '../../coap_request.dart';
import '../../coap_response.dart';
import '../../event/coap_event_bus.dart';
import '../../net/exchange.dart';
import '../../net/multicast_exchange.dart';
import '../base_layer.dart';

/// Top layer
class CoapStackTopLayer extends BaseLayer {
  @override
  void sendRequest(
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
    initialExchange.request ??= request;
  }

  @override
  void receiveResponse(
    final CoapExchange initialExchange,
    final CoapResponse response,
  ) {
    if (response.hasOption(OptionType.block2) ||
        response.hasOption(OptionType.block1)) {
      initialExchange.request!.token ??= response.token;

      super.receiveResponse(initialExchange, response);
      return;
    }

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
    super.receiveResponse(initialExchange, response);
  }
}
