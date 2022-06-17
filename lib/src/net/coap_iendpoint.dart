/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

import '../coap_config.dart';
import '../coap_empty_message.dart';
import '../coap_request.dart';
import '../coap_response.dart';
import 'coap_exchange.dart';
import 'coap_internet_address.dart';
import 'coap_ioutbox.dart';

/// Events
/// Represents a communication endpoint multiplexing CoAP message exchanges
/// between (potentially multiple) clients and servers.
abstract class CoapIEndPoint {
  /// The endpoint's destination
  CoapInternetAddress? get destination;

  /// Gets this endpoint's configuration.
  DefaultCoapConfig get config;

  /// The next message id to use
  int get nextMessageId;

  /// Gets the outbox.
  CoapIOutbox get outbox;

  /// Starts this endpoint and all its components.
  Future<void> start();

  /// The namespace which the endpoint belongs to
  String get namespace;

  /// Stops this endpoint and all its components
  void stop();

  /// Clears this endpoint
  void clear();

  /// Sends the specified request.
  void sendEpRequest(final CoapRequest request);

  /// Sends the specified response.
  void sendEpResponse(final CoapExchange exchange, final CoapResponse response);

  /// Sends the specified empty message.
  void sendEpEmptyMessage(
    final CoapExchange exchange,
    final CoapEmptyMessage message,
  );
}
