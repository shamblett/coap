/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

class CoapSweepDeduplicator implements CoapIDeduplicator {
  static CoapILogger _log = new CoapLogManager("console").logger;

  CoapSweepDeduplicator(CoapConfig config) {
    _config = config;
  }

  Map<CoapKeyId, CoapExchange> _incomingMessages =
      new Map<CoapKeyId, CoapExchange>();
  Timer _timer;
  CoapConfig _config;

  void start() {
    _timer = new Timer.periodic(
        new Duration(milliseconds: _config.markAndSweepInterval), _sweep);
  }

  void stop() {
    _timer.cancel();
  }

  void clear() {
    stop();
    _incomingMessages.clear();
  }

  CoapExchange findPrevious(CoapKeyId key, CoapExchange exchange) {
    CoapExchange prev;
    if (_incomingMessages.containsKey(key)) {
      prev = _incomingMessages[key];
    }
    _incomingMessages[key] = exchange;
    return prev;
  }

  CoapExchange find(CoapKeyId key) {
    if (_incomingMessages.containsKey(key)) {
      return _incomingMessages[key];
    }
    return null;
  }

  void _sweep(Timer timer) {
    _log.debug("Start Mark-And-Sweep with ${_incomingMessages.length} entries");

    final DateTime oldestAllowed = new DateTime.now()
      ..add(new Duration(milliseconds: _config.exchangeLifetime));
    final List<CoapKeyId> keysToRemove = new List<CoapKeyId>();
    _incomingMessages.forEach((CoapKeyId key, CoapExchange value) {
      if (value.timestamp.isBefore(oldestAllowed)) {
        _log.debug("Mark-And-Sweep removes $key");
        keysToRemove.add(key);
      }
    });
    for (CoapKeyId key in keysToRemove) {
      _incomingMessages.remove(key);
    }
  }
}
