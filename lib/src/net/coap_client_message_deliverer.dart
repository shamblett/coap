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
  void deliverRequest(CoapExchange exchange) {
    exchange.sendReject();
  }

  @override
  void deliverResponse(CoapExchange exchange, CoapResponse response) {
    if (exchange == null) {
      throw ArgumentError.notNull('exchange');
    }
    if (response == null) {
      throw ArgumentError.notNull('response');
    }
    if (exchange.request == null) {
      throw ArgumentError.notNull('request');
    }
    exchange.request.response = response;
  }
}
