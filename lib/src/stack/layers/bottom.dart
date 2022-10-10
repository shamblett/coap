import '../../coap_empty_message.dart';
import '../../coap_request.dart';
import '../../coap_response.dart';
import '../../net/exchange.dart';
import '../base_layer.dart';

/// Bottom layer
class BottomLayer extends BaseLayer {
  @override
  void sendRequest(
    final CoapExchange? initialExchange,
    final CoapRequest request,
  ) {
    initialExchange?.outbox!.sendRequest(initialExchange, request);
  }

  @override
  void sendResponse(
    final CoapExchange initialExchange,
    final CoapResponse response,
  ) {
    initialExchange.outbox!.sendResponse(initialExchange, response);
  }

  @override
  void sendEmptyMessage(
    final CoapExchange initialExchange,
    final CoapEmptyMessage message,
  ) {
    initialExchange.outbox!.sendEmptyMessage(initialExchange, message);
  }
}
