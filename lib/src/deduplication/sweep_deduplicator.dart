/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/05/2018
 * Copyright :  S.Hamblett
 */

import 'dart:async';

import '../coap_config.dart';
import '../net/exchange.dart';
import 'deduplicator.dart';

/// Sweep deduplicator
class SweepDeduplicator implements Deduplicator {
  /// Construction
  SweepDeduplicator(this._config);

  Timer? _timer;
  final Map<int?, CoapExchange> _incomingMessages = <int?, CoapExchange>{};
  final DefaultCoapConfig _config;

  @override
  void start() {
    _timer ??= Timer.periodic(
      Duration(milliseconds: _config.markAndSweepInterval),
      _sweep,
    );
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void clear() {
    stop();
    _incomingMessages.clear();
  }

  @override
  CoapExchange? findPrevious(final int? key, final CoapExchange exchange) {
    CoapExchange? prev;
    if (_incomingMessages.containsKey(key)) {
      prev = _incomingMessages[key];
    }
    _incomingMessages[key] = exchange;
    return prev;
  }

  @override
  CoapExchange? find(final int? key) {
    if (_incomingMessages.containsKey(key)) {
      return _incomingMessages[key];
    }
    return null;
  }

  void _sweep(final Timer timer) {
    final oldestAllowed = DateTime.now()
      ..add(Duration(milliseconds: _config.exchangeLifetime));
    _incomingMessages.removeWhere(
      (final key, final value) => value.timestamp!.isBefore(oldestAllowed),
    );
  }
}
