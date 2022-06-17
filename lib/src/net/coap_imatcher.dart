/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/05/2018
 * Copyright :  S.Hamblett
 */

import '../coap_empty_message.dart';
import '../coap_request.dart';
import '../coap_response.dart';
import 'coap_exchange.dart';

/// Interfca efor the Matcher class
abstract class CoapIMatcher {
  /// Clear
  void clear();

  /// Start
  void start();

  /// Stop
  void stop();

  /// Send a request
  void sendRequest(final CoapExchange exchange, final CoapRequest request);

  /// Send a response
  void sendResponse(final CoapExchange exchange, final CoapResponse response);

  /// Send an empty message
  void sendEmptyMessage(
    final CoapExchange exchange,
    final CoapEmptyMessage message,
  );

  /// Received request
  CoapExchange receiveRequest(final CoapRequest request);

  /// Received response
  CoapExchange? receiveResponse(final CoapResponse response);

  /// Received empty message
  CoapExchange? receiveEmptyMessage(final CoapEmptyMessage message);
}
