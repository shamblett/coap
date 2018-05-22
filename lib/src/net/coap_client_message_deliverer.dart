/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/05/2017
 * Copyright :  S.Hamblett
 */

part of coap;

class CoapClientMessageDeliverer implements CoapIMessageDeliverer {
  void deliverRequest(CoapExchange exchange) {
    exchange.sendReject();
  }

  void deliverResponse(CoapExchange exchange, CoapResponse response) {
    if (exchange == null) {
      throw new ArgumentError.notNull("exchange");
    }
    if (response == null) {
      throw new ArgumentError.notNull("response");
    }
    if (exchange.request == null) {
      throw new ArgumentError.notNull("request");
    }
    exchange.request.response = response;
  }
}
