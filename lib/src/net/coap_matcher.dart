/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

class CoapMatcher implements CoapIMatcher {
  CoapMatcher(CoapConfig config) {
    _deduplicator = CoapDeduplicatorFactory.createDeduplicator(config);
    if (config.useRandomIDStart) {
      _currentId = new Random().nextInt(1 << 16);
    }
    clientEventBus.on<CoapCompletedEvent>().listen(onExchangeCompleted);
  }

  static CoapILogger _log = new CoapLogManager("console").logger;

  /// For all
  Map<CoapKeyId, CoapExchange> _exchangesById =
      new Map<CoapKeyId, CoapExchange>();

  /// For outgoing
  Map<CoapKeyToken, CoapExchange> _exchangesByToken =
      new Map<CoapKeyToken, CoapExchange>();

  /// For blockwise
  Map<CoapKeyUri, CoapExchange> _ongoingExchanges =
      new Map<CoapKeyUri, CoapExchange>();

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
    _exchangesById.clear();
    _exchangesByToken.clear();
    _ongoingExchanges.clear();
    _deduplicator.clear();
  }

  void sendRequest(CoapExchange exchange, CoapRequest request) {
    if (request.id == CoapMessage.none) {
      request.id = _currentId == null ? (1 << 16) : _currentId;

      // The request is a CON or NON and must be prepared for these responses
      // - CON => ACK / RST / ACK+response / CON+response / NON+response
      // - NON => RST / CON+response / NON+response
      // If this request goes lost, we do not get anything back.

      // The MID is from the local namespace -- use blank address
      final CoapKeyId keyId = new CoapKeyId(request.id, null);
      final CoapKeyToken keyToken = new CoapKeyToken(request.token);
      _log.debug("Stored open request by $keyId + $keyToken");

      _exchangesById[keyId] = exchange;
      _exchangesByToken[keyToken] = exchange;
    }
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
      _exchangesById[keyId] = exchange;
    }

    // Only CONs and Observe keep the exchange active
    if (response.type != CoapMessageType.con && response.last) {
      exchange.complete = true;
    }
  }

  void sendEmptyMessage(CoapExchange exchange, CoapEmptyMessage message) {
    if (message.type == CoapMessageType.rst && exchange != null) {
      // We have rejected the request or response
      exchange.complete = true;
    }
  }

  CoapExchange receiveRequest(CoapRequest request) {
    // This request could be
    //  - Complete origin request => deliver with new exchange
    //  - One origin block        => deliver with ongoing exchange
    //  - Complete duplicate request or one duplicate block (because client got no ACK)
    //     =>
    //		if ACK got lost => resend ACK
    //		if ACK+response got lost => resend ACK+response
    //		if nothing has been sent yet => do nothing
    // (Retransmission is supposed to be done by the retransm. layer)

    CoapKeyId keyId = new CoapKeyId(request.id, request.source);

    // The differentiation between the case where there is a Block1 or
    // Block2 option and the case where there is none has the advantage that
    // all exchanges that do not need blockwise transfer have simpler and
    // faster code than exchanges with blockwise transfer.

    if (!request.hasOption(optionTypeBlock1) &&
        !request.hasOption(optionTypeBlock2)) {
      final CoapExchange exchange =
          new CoapExchange(request, CoapOrigin.remote);
      final CoapExchange previous = _deduplicator.findPrevious(keyId, exchange);
      if (previous == null) {
        return exchange;
      } else {
        _log.info("Duplicate request: $request");
        request.duplicate = true;
        return previous;
      }
    } else {
      final CoapKeyUri keyUri = new CoapKeyUri(request.uri, request.source);
      _log.debug("Looking up ongoing exchange for $keyUri");

      final CoapExchange ongoing = _ongoingExchanges[keyUri];
      if (ongoing != null) {
        final CoapExchange prev = _deduplicator.findPrevious(keyId, ongoing);
        if (prev != null) {
          _log.info("Duplicate ongoing request: $request");
          request.duplicate = true;
        } else {
          // The exchange is continuing, we can (i.e., must) clean up the previous response
          if (ongoing.currentResponse.type != CoapMessageType.ack &&
              !ongoing.currentResponse.hasOption(optionTypeObserve)) {
            keyId = new CoapKeyId(ongoing.currentResponse.id, null);
            _log.debug("Ongoing exchange got new request, cleaning up $keyId");
            _exchangesById.remove(keyId);
          }
        }
        return ongoing;
      } else {
        // We have no ongoing exchange for that request block.

        // Note the difficulty of the following code: The first message
        // of a blockwise transfer might arrive twice due to a
        // retransmission. The new Exchange must be inserted in both the
        // hash map 'ongoing' and the deduplicator. They must agree on
        // which exchange they store!

        final CoapExchange exchange =
            new CoapExchange(request, CoapOrigin.remote);
        final CoapExchange previous =
            _deduplicator.findPrevious(keyId, exchange);
        if (previous == null) {
          _log.debug("New ongoing request, storing $keyUri for $request");
          _ongoingExchanges[keyUri] = exchange;
          return exchange;
        } else {
          _log.info("Duplicate initial request: $request");
          request.duplicate = true;
          return previous;
        }
      } // if ongoing
    } // if blockwise
  }

  CoapExchange receiveResponse(CoapResponse response) {
    // This response could be
    // The first CON/NON/ACK+response => deliver
    // Retransmitted CON (because client got no ACK)
    //	=> resend ACK

    CoapKeyId keyId;
    if (response.type == CoapMessageType.ack) {
      // Own namespace
      keyId = new CoapKeyId(response.id, null);
    } else {
      // Remote namespace
      keyId = new CoapKeyId(response.id, response.source);
    }

    final CoapKeyToken keyToken = new CoapKeyToken(response.token);

    final CoapExchange exchange = _exchangesByToken[keyToken];
    if (exchange != null) {
      // There is an exchange with the given token
      final CoapExchange prev = _deduplicator.findPrevious(keyId, exchange);
      if (prev != null) {
        // (and thus it holds: prev == exchange)
        _log.info("Duplicate response for open exchange: $response");
        response.duplicate = true;
      } else {
        keyId = new CoapKeyId(exchange.currentRequest.id, null);
        _log.debug("Exchange got response: Cleaning up $keyId");
        _exchangesById.remove(keyId);
      }

      if (response.type == CoapMessageType.ack &&
          exchange.currentRequest.id != response.id) {
        // The token matches but not the MID. This is a response for an older exchange
        _log.warn(
            "Possible MID reuse before lifetime end: ${response.tokenString} expected MID ${exchange.currentRequest.id} but received ${response.id}");
      }

      return exchange;
    } else {
      // There is no exchange with the given token.
      if (response.type != CoapMessageType.ack) {
        // Only act upon separate responses
        final CoapExchange prev = _deduplicator.find(keyId);
        if (prev != null) {
          _log.info("Duplicate response for completed exchange: $response");
          response.duplicate = true;
          return prev;
        }
      } else {
        _log.info(
            "Ignoring unmatchable piggy-backed response from ${response.source} : $response");
      }
      // Ignore response
      return null;
    }
  }

  CoapExchange receiveEmptyMessage(CoapEmptyMessage message) {
    // Local namespace
    final CoapKeyId keyId = new CoapKeyId(message.id, null);
    final CoapExchange exchange = _exchangesById[keyId];
    if (exchange != null) {
      _log.debug("Exchange got reply: Cleaning up $keyId");
      _exchangesById.remove(keyId);
      return exchange;
    } else {
      _log.info(
          "Ignoring unmatchable empty message from ${message.source} : $message");
      return null;
    }
  }

  void onExchangeCompleted(CoapCompletedEvent event) {
    final CoapExchange exchange = event.exchange;

    if (exchange.origin == CoapOrigin.local) {
      // This endpoint created the Exchange by issuing a request
      final CoapKeyId keyId = new CoapKeyId(exchange.currentRequest.id, null);
      final CoapKeyToken keyToken =
          new CoapKeyToken(exchange.currentRequest.token);
      _log.debug("Exchange completed: Cleaning up $keyToken");

      _exchangesByToken.remove(keyToken);
      // In case an empty ACK was lost
      _exchangesById.remove(keyId);
    } else // Origin.Remote
    {
      // This endpoint created the Exchange to respond a request
      final CoapResponse response = exchange.currentResponse;
      if (response != null && response.type != CoapMessageType.ack) {
        // Only response MIDs are stored for ACK and RST, no reponse Tokens
        final CoapKeyId midKey = new CoapKeyId(response.id, null);
        _exchangesById.remove(midKey);
      }

      final CoapRequest request = exchange.currentRequest;
      if (request != null &&
          (request.hasOption(optionTypeBlock1) ||
              response.hasOption(optionTypeBlock2))) {
        final CoapKeyUri uriKey = new CoapKeyUri(request.uri, request.source);
        _log.debug("Remote ongoing completed, cleaning up $uriKey");
        _ongoingExchanges.remove(uriKey);
      }

      // Remove all remaining NON-notifications if this exchange is an observe relation
      final CoapObserveRelation relation = exchange.relation;
      if (relation != null) {
        _removeNotificatoinsOf(relation);
      }
    }
  }

  void _removeNotificatoinsOf(CoapObserveRelation relation) {
    _log.debug("Remove all remaining NON-notifications of observe relation");

    for (CoapResponse previous in relation.clearNotifications()) {
      // Notifications are local MID namespace
      final CoapKeyId keyId = new CoapKeyId(previous.id, null);
      _exchangesById.remove(keyId);
    }
  }
}
