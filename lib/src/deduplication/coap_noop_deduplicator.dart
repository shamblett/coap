/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// A dummy implementation that does no deduplication.
class CoapNoopDeduplicator implements CoapIDeduplicator {
  @override
  void start() {
    // Do nothing
  }

  @override
  void stop() {
    // Do nothing
  }

  @override
  void clear() {
    // Do nothing
  }

  @override
  CoapExchange findPrevious(CoapKeyId key, CoapExchange exchange) => null;

  @override
  CoapExchange find(CoapKeyId key) => null;
}
