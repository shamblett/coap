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

  void sendResponse(CoapExchange exchange, CoapResponse response) {
    if (response.id == CoapMessage.none) response.id = _currentId % (1 << 16);

    // The response is a CON or NON or ACK and must be prepared for these
    // - CON => ACK / RST // we only care to stop retransmission
    // - NON => RST // we only care for observe
    // - ACK => nothing!
    // If this response goes lost, we must be prepared to get the same
    // CON/NON request with same MID again. We then find the corresponding
    // exchange and the ReliabilityLayer resends this response.

    // If this is a CON notification we now can forget all previous NON notifications
    if (response.type == CoapMessageType.con ||
        response.type == CoapMessageType.ack) {
      final CoapObserveRelation relation = exchange.relation;
      if (relation != null) {
        _removeNotificatoinsOf(relation);
      }
    }

    // Blockwise transfers are identified by URI and remote endpoint
    if (response.hasOption(optionTypeBlock2)) {
      final CoapRequest request = exchange.currentRequest;
      final CoapKeyUri keyUri =
      new CoapKeyUri(request.uri, response.destination);
      // Observe notifications only send the first block, hence do not store them as ongoing
      if (exchange.responseBlockStatus != null &&
          !response.hasOption(optionTypeObserve)) {
        // Remember ongoing blockwise GET requests
        if (CoapUtil.put(_ongoingExchanges, keyUri, exchange) == null) {
          _log.debug(
              "Ongoing Block2 started late, storing $keyUri for $request");
        } else {
          _log.debug("Ongoing Block2 continued, storing $keyUri for $request");
        }
      } else {
        _log.debug(
            "Ongoing Block2 completed, cleaning up $keyUri for $request");
        _ongoingExchanges.remove(keyUri);
      }
    }

    // Insert CON and NON to match ACKs and RSTs to the exchange
    // Do not insert ACKs and RSTs.
    if (response.type == CoapMessageType.con ||
        response.type == CoapMessageType.non) {
      final CoapKeyId keyId = new CoapKeyId(response.id, null);
      _exchangesByID[keyId] = exchange;
    }

    // Only CONs and Observe keep the exchange active
    if (response.type != CoapMessageType.con && response.last) {
      exchange.complete = true;
    }
  }

  void onExchangeCompleted(events.Event<CoapCompletedEvent> event) {}

  void _removeNotificatoinsOf(CoapObserveRelation relation) {
    _log.debug("Remove all remaining NON-notifications of observe relation");

    for (CoapResponse previous in relation.clearNotifications()) {
      // Notifications are local MID namespace
      final CoapKeyId keyId = new CoapKeyId(previous.id, null);
      _exchangesByID.remove(keyId);
    }
  }
}
