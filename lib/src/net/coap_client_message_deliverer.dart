/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/05/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Message deliverer
class CoapClientMessageDeliverer implements CoapIMessageDeliverer {
  @override
  void deliverRequest(CoapExchange exchange) {}

  @override
  void deliverResponse(CoapExchange exchange, CoapResponse response) {
    exchange.request!.response = response;
  }
}
