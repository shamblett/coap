/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Sweep deduplicator
class CoapSweepDeduplicator implements CoapIDeduplicator {
  /// Construction
  CoapSweepDeduplicator(DefaultCoapConfig config) {
    _config = config;
  }

  final Map<CoapKeyId, CoapExchange> _incomingMessages =
      <CoapKeyId, CoapExchange>{};
  Timer? _timer;
  late DefaultCoapConfig _config;

  @override
  void start() {
    _timer ??= Timer.periodic(
        Duration(milliseconds: _config.markAndSweepInterval), _sweep);
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
  CoapExchange? findPrevious(CoapKeyId key, CoapExchange exchange) {
    CoapExchange? prev;
    if (_incomingMessages.containsKey(key)) {
      prev = _incomingMessages[key];
    }
    _incomingMessages[key] = exchange;
    return prev;
  }

  @override
  CoapExchange? find(CoapKeyId key) {
    if (_incomingMessages.containsKey(key)) {
      return _incomingMessages[key];
    }
    return null;
  }

  void _sweep(Timer timer) {
    final oldestAllowed = DateTime.now()
      ..add(Duration(milliseconds: _config.exchangeLifetime));
    final keysToRemove = <CoapKeyId>[];
    _incomingMessages.forEach((CoapKeyId key, CoapExchange value) {
      if (value.timestamp!.isBefore(oldestAllowed)) {
        keysToRemove.add(key);
      }
    });
    keysToRemove.forEach(_incomingMessages.remove);
  }
}
