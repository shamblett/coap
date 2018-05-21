/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// A dummy implementation that does no deduplication.
class CoapNoopDeduplicator implements CoapIDeduplicator {
  void start() {
    // Do nothing
  }

  void stop() {
    // Do nothing
  }

  void clear() {
    // Do nothing
  }

  CoapExchange findPrevious(CoapKeyId key, CoapExchange exchange) {
    return null;
  }

  CoapExchange find(CoapKeyId key) {
    return null;
  }
}
