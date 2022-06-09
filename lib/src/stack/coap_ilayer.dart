/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/05/2018
 * Copyright :  S.Hamblett
 */

import '../coap_empty_message.dart';
import '../coap_request.dart';
import '../coap_response.dart';
import '../net/coap_exchange.dart';
import '../tasks/coap_iexecutor.dart';

/// Represent a next layer in the stack.
abstract class CoapINextLayer {
  /// Sends a request to next layer.
  void sendRequest(final CoapExchange? exchange, final CoapRequest request);

  /// Sends a response to next layer.
  void sendResponse(final CoapExchange exchange, final CoapResponse response);

  /// Sends an empty message to next layer.
  void sendEmptyMessage(
    final CoapExchange exchange,
    final CoapEmptyMessage message,
  );

  /// Receives a request to next layer.
  void receiveRequest(final CoapExchange exchange, final CoapRequest request);

  /// Receives a response to next layer.
  void receiveResponse(
    final CoapExchange exchange,
    final CoapResponse response,
  );

  /// Receives an empty message to next layer.
  void receiveEmptyMessage(
    final CoapExchange exchange,
    final CoapEmptyMessage message,
  );
}

/// Represents a layer in the stack.
abstract class CoapILayer {
  /// Gets or set the executor to schedule tasks.
  CoapIExecutor? executor;

  /// Filters a request sending event.
  void sendRequest(
    final CoapINextLayer nextLayer,
    final CoapExchange exchange,
    final CoapRequest request,
  );

  /// Filters a response sending event.
  void sendResponse(
    final CoapINextLayer nextLayer,
    final CoapExchange exchange,
    final CoapResponse response,
  );

  /// Filters an empty message sending event.
  void sendEmptyMessage(
    final CoapINextLayer nextLayer,
    final CoapExchange exchange,
    final CoapEmptyMessage message,
  );

  /// Filters a request receiving event.
  void receiveRequest(
    final CoapINextLayer nextLayer,
    final CoapExchange exchange,
    final CoapRequest request,
  );

  /// Filters a response receiving event.
  void receiveResponse(
    final CoapINextLayer nextLayer,
    final CoapExchange exchange,
    final CoapResponse response,
  );

  /// Filters an empty message receiving event.
  void receiveEmptyMessage(
    final CoapINextLayer nextLayer,
    final CoapExchange exchange,
    final CoapEmptyMessage message,
  );
}
