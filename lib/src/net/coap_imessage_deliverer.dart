/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Provides methods for delivering inbound CoAP messages to an appropriate processor.
abstract class CoapIMessageDeliverer {
  /// Delivers an inbound CoAP request to an appropriate resource.
  void deliverRequest(CoapExchange exchange);

  /// Delivers an inbound CoAP response message to its corresponding request.
  void deliverResponse(CoapExchange exchange, CoapResponse response);
}
