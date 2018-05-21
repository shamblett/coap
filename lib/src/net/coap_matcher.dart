/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

class CoapMatcher extends Object
    with events.EventEmitter
    implements CoapIMatcher {
  CoapMatcher(CoapConfig config) {
    _deduplicator = CoapDeduplicatorFactory.createDeduplicator(config);
    if (config.useRandomIDStart) {
      _currentId = new Random().nextInt(1 << 16);
    }
  }

  static CoapILogger _log = new CoapLogManager("console").logger;

  /// For all
  Map<CoapKeyId, CoapExchange> _exchangesByID =
      new Map<CoapKeyId, CoapExchange>();

  /// For outgoing
  Map<CoapKeyToken, CoapExchange> _exchangesByToken =
      new Map<CoapKeyToken, CoapExchange>();

  /// For blockwise
  Map<CoapKeyUri, CoapExchange> _ongoingExchanges =
      new Map<CoapKeyUri, CoapExchange>();

  int _running;
  int _currentId;
  CoapIDeduplicator _deduplicator;

  void start() {
    _deduplicator.start();
  }

  void stop() {
    _deduplicator.stop();
    clear();
  }

  void clear() {
    _exchangesByID.clear();
    _exchangesByToken.clear();
    _ongoingExchanges.clear();
    _deduplicator.clear();
  }

  void sendRequest(CoapExchange exchange, CoapRequest request) {
    if (request.id == CoapMessage.none) request.id = _currentId % (1 << 16);

    // The request is a CON or NON and must be prepared for these responses
    // - CON => ACK / RST / ACK+response / CON+response / NON+response
    // - NON => RST / CON+response / NON+response
    // If this request goes lost, we do not get anything back.

    // The MID is from the local namespace -- use blank address
    final CoapKeyId keyId = new CoapKeyId(request.id, null);
    final CoapKeyToken keyToken = new CoapKeyToken(request.token);
    addEventAction(CoapCompletedEvent, onExchangeCompleted);
    _log.debug("Stored open request by $keyId + $keyToken");

    _exchangesByID[keyId] = exchange;
    _exchangesByToken[keyToken] = exchange;
  }

  void onExchangeCompleted(events.Event<CoapCompletedEvent> event) {}
}
