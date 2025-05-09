/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/05/2018
 * Copyright :  S.Hamblett
 */

import '../net/exchange.dart';
import 'deduplicator.dart';

/// A dummy implementation that does no deduplication.
class NoopDeduplicator implements Deduplicator {
  @override
  void start() {
    // Do nothing
    return;
  }

  @override
  void stop() {
    // Do nothing
    return;
  }

  @override
  void clear() {
    // Do nothing
    return;
  }

  @override
  CoapExchange? findPrevious(final int? key, final CoapExchange exchange) =>
      null;

  @override
  CoapExchange? find(final int? key) => null;
}
