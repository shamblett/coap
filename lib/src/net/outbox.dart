/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

import '../coap_empty_message.dart';
import '../coap_request.dart';
import '../coap_response.dart';
import 'exchange.dart';

/// Interface for an Outbox
abstract class Outbox {
  /// Sends the specified request over the connector that the
  /// stack is connected to.
  void sendRequest(final CoapExchange exchange, final CoapRequest request);

  /// Sends the specified response over the connector that the
  /// stack is connected to.
  void sendResponse(final CoapExchange exchange, final CoapResponse response);

  /// Sends the specified empty message over the connector that the
  /// stack is connected to.
  void sendEmptyMessage(
    final CoapExchange exchange,
    final CoapEmptyMessage message,
  );
}
