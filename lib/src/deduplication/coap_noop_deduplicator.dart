/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/05/2018
 * Copyright :  S.Hamblett
 */

import '../net/coap_exchange.dart';
import 'coap_ideduplicator.dart';

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
  CoapExchange? findPrevious(final int? key, final CoapExchange exchange) =>
      null;

  @override
  CoapExchange? find(final int? key) => null;
}
