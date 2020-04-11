/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Matcher class
class CoapMatcher implements CoapIMatcher {
  /// Construction
  CoapMatcher(DefaultCoapConfig config) {
    _deduplicator = CoapDeduplicatorFactory.createDeduplicator(config);
    if (config.useRandomIDStart) {
      _currentId = Random().nextInt(1 << 16);
    }
    _eventBus.on<CoapCompletedEvent>().listen(onExchangeCompleted);
  }

  final CoapILogger _log = CoapLogManager().logger;
  final CoapEventBus _eventBus = CoapEventBus();

  /// For all
  final Map<CoapKeyId, CoapExchange> _exchangesById =
      <CoapKeyId, CoapExchange>{};

  /// For outgoing
  final Map<CoapKeyToken, CoapExchange> _exchangesByToken =
      <CoapKeyToken, CoapExchange>{};

  /// For blockwise
  final Map<CoapKeyUri, CoapExchange> _ongoingExchanges =
      <CoapKeyUri, CoapExchange>{};

  int _currentId;
  CoapIDeduplicator _deduplicator;

  @override
  void start() {
    _deduplicator.start();
  }

  @override
  void stop() {
    _deduplicator?.stop();
  }

  @override
  void clear() {
    _exchangesById.clear();
    _exchangesByToken.clear();
    _ongoingExchanges.clear();
    _deduplicator.clear();
  }

  @override
  void sendRequest(CoapExchange exchange, CoapRequest request) {
    if (request.id == CoapMessage.none) {
      request.id = _currentId ?? (1 << 16);
    }

    // The request is a CON or NON and must be prepared for these responses
    // - CON => ACK / RST / ACK+response / CON+response / NON+response
    // - NON => RST / CON+response / NON+response
    // If this request goes lost, we do not get anything back.

    // The MID is from the local namespace -- use blank address
    final keyId = CoapKeyId(request.id);
    final keyToken = CoapKeyToken(request.token);
    _log.info('Matcher - Stored open request by $keyId + $keyToken');
    _exchangesById[keyId] = exchange;
    _exchangesByToken[keyToken] = exchange;
  }

  @override
  void sendResponse(CoapExchange exchange, CoapResponse response) {
    if (response.id == CoapMessage.none) {
      response.id = _currentId % (1 << 16);
    }

    // The response is a CON or NON or ACK and must be prepared for these
    // - CON => ACK / RST // we only care to stop retransmission
    // - NON => RST // we only care for observe
    // - ACK => nothing!
    // If this response goes lost, we must be prepared to get the same
    // CON/NON request with same MID again. We then find the corresponding
    // exchange and the ReliabilityLayer resends this response.

    // If this is a CON notification we now can forget all previous
    // NON notifications.
    if (response.type == CoapMessageType.con ||
        response.type == CoapMessageType.ack) {
      final relation = exchange.relation;
      if (relation != null) {
        _removeNotificatoinsOf(relation);
      }
    }

    // Blockwise transfers are identified by URI and remote endpoint
    if (response.hasOption(optionTypeBlock2)) {
      final request = exchange.currentRequest;
      final keyUri = CoapKeyUri(request.uri, response.destination);
      // Observe notifications only send the first block,
      // hence do not store them as ongoing.
      if (exchange.responseBlockStatus != null &&
          !response.hasOption(optionTypeObserve)) {
        // Remember ongoing blockwise GET requests
        if (CoapUtil.put(_ongoingExchanges, keyUri, exchange) == null) {
          _log.info('Matcher - Ongoing Block2 started late, '
              'storing $keyUri for $request');
        } else {
          _log.info('Matcher - Ongoing Block2 continued, '
              'storing $keyUri for $request');
        }
      } else {
        _log.info('Matcher - Ongoing Block2 completed, '
            'cleaning up $keyUri for $request');
        _ongoingExchanges.remove(keyUri);
      }
    }

    // Insert CON and NON to match ACKs and RSTs to the exchange
    // Do not insert ACKs and RSTs.
    if (response.type == CoapMessageType.con ||
        response.type == CoapMessageType.non) {
      final keyId = CoapKeyId(response.id);
      _exchangesById[keyId] = exchange;
    }

    // Only CONs and Observe keep the exchange active
    if (response.type != CoapMessageType.con && response.last) {
      exchange.complete = true;
    }
  }

  @override
  void sendEmptyMessage(CoapExchange exchange, CoapEmptyMessage message) {
    if (message.type == CoapMessageType.rst && exchange != null) {
      // We have rejected the request or response
      exchange.complete = true;
    }
  }

  @override
  CoapExchange receiveRequest(CoapRequest request) {
    // This request could be
    //  - Complete origin request => deliver with new exchange
    //  - One origin block        => deliver with ongoing exchange
    //  - Complete duplicate request or one duplicate block
    //  (because client got no ACK)
    //     =>
    //		if ACK got lost => resend ACK
    //		if ACK+response got lost => resend ACK+response
    //		if nothing has been sent yet => do nothing
    // (Retransmission is supposed to be done by the retransm. layer)

    var keyId = CoapKeyId(request.id);

    // The differentiation between the case where there is a Block1 or
    // Block2 option and the case where there is none has the advantage that
    // all exchanges that do not need blockwise transfer have simpler and
    // faster code than exchanges with blockwise transfer.

    if (!request.hasOption(optionTypeBlock1) &&
        !request.hasOption(optionTypeBlock2)) {
      final exchange = CoapExchange(request, CoapOrigin.remote);
      final previous = _deduplicator.findPrevious(keyId, exchange);
      if (previous == null) {
        return exchange;
      } else {
        _log.info('Matcher - Duplicate request: $request');
        request.duplicate = true;
        return previous;
      }
    } else {
      final keyUri = CoapKeyUri(request.uri, request.source);
      _log.info('Matcher - Looking up ongoing exchange for $keyUri');

      final ongoing = _ongoingExchanges[keyUri];
      if (ongoing != null) {
        final prev = _deduplicator.findPrevious(keyId, ongoing);
        if (prev != null) {
          _log.info('Matcher - Duplicate ongoing request: $request');
          request.duplicate = true;
        } else {
          // The exchange is continuing, we can (i.e., must)
          // clean up the previous response.
          if (ongoing.currentResponse.type != CoapMessageType.ack &&
              !ongoing.currentResponse.hasOption(optionTypeObserve)) {
            keyId = CoapKeyId(ongoing.currentResponse.id);
            _log.info('Matcher - Ongoing exchange got new request, '
                'cleaning up $keyId');
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

        final exchange = CoapExchange(request, CoapOrigin.remote);
        final previous = _deduplicator.findPrevious(keyId, exchange);
        if (previous == null) {
          _log.info(
              'Matcher - New ongoing request, storing $keyUri for $request');
          _ongoingExchanges[keyUri] = exchange;
          return exchange;
        } else {
          _log.info('Matcher - Duplicate initial request: $request');
          request.duplicate = true;
          return previous;
        }
      } // if ongoing
    } // if blockwise
  }

  @override
  CoapExchange receiveResponse(CoapResponse response) {
    // This response could be
    // The first CON/NON/ACK+response => deliver
    // Retransmitted CON (because client got no ACK)
    //	=> resend ACK
    _log.info('Matcher - received response $response');
    var keyId = CoapKeyId(response.id);
    final keyToken = CoapKeyToken(response.token);
    final exchange = _exchangesByToken[keyToken];
    if (exchange != null) {
      // There is an exchange with the given token
      final prev = _deduplicator.findPrevious(keyId, exchange);
      if (prev != null) {
        // (and thus it holds: prev == exchange)
        _log.info('Matcher - Duplicate response for open exchange');
        response.duplicate = true;
      } else {
        keyId = CoapKeyId(exchange.currentRequest.id);
        _log.info('Matcher - cleaning up $keyId');
        _exchangesById.remove(keyId);
      }

      if (response.type == CoapMessageType.ack &&
          exchange.currentRequest.id != response.id) {
        // The token matches but not the MID. This is a
        // response for an older exchange
        _log.warn('Matcher - Possible MID reuse before lifetime end: '
            '${response.tokenString} expected MID '
            '${exchange.currentRequest.id} but received ${response.id}');
      }

      return exchange;
    } else {
      // There is no exchange with the given token.
      if (response.type != CoapMessageType.ack) {
        // Only act upon separate responses
        final prev = _deduplicator.find(keyId);
        if (prev != null) {
          _log.warn(
              'Matcher - Duplicate response for completed exchange: $response');
          response.duplicate = true;
          return prev;
        }
      } else {
        _log.warn('Matcher - Ignoring unmatchable piggy-backed '
            'response from ${response.source.address.host} : $response');
      }
      // Ignore response
      return null;
    }
  }

  @override
  CoapExchange receiveEmptyMessage(CoapEmptyMessage message) {
    // Local namespace
    final keyId = CoapKeyId(message.id);
    final exchange = _exchangesById[keyId];
    if (exchange != null) {
      _log.info('Exchange got reply: Cleaning up $keyId');
      _exchangesById.remove(keyId);
      return exchange;
    } else {
      _log.warn('Matcher - Ignoring unmatchable empty message '
          'from ${message.source} : $message');
      return null;
    }
  }

  /// Exchange completed event handler
  void onExchangeCompleted(CoapCompletedEvent event) {
    final exchange = event.exchange;

    if (exchange.origin == CoapOrigin.local) {
      // This endpoint created the Exchange by issuing a request
      final keyId = CoapKeyId(exchange.currentRequest.id);
      final keyToken = CoapKeyToken(exchange.currentRequest.token);
      _log.info('Matcher - Exchange completed: Cleaning up $keyToken');

      _exchangesByToken.remove(keyToken);
      // In case an empty ACK was lost
      _exchangesById.remove(keyId);
    } else // Origin.Remote
    {
      // This endpoint created the Exchange to respond a request
      final response = exchange.currentResponse;
      if (response != null && response.type != CoapMessageType.ack) {
        // Only response MIDs are stored for ACK and RST, no reponse Tokens
        final midKey = CoapKeyId(response.id);
        _exchangesById.remove(midKey);
      }

      final request = exchange.currentRequest;
      if (request != null &&
          (request.hasOption(optionTypeBlock1) ||
              (response != null && response.hasOption(optionTypeBlock2)))) {
        final uriKey = CoapKeyUri(request.uri, request.source);
        _log.info('Matcher - Remote ongoing completed, cleaning up $uriKey');
        _ongoingExchanges.remove(uriKey);
      }

      // Remove all remaining NON-notifications if this exchange is
      // an observe relation.
      final relation = exchange.relation;
      if (relation != null) {
        _removeNotificatoinsOf(relation);
      }
    }
  }

  void _removeNotificatoinsOf(CoapObserveRelation relation) {
    _log.info(
        'Matcher - Remove all remaining NON-notifications of observe relation');

    for (final previous in relation.clearNotifications()) {
      // Notifications are local MID namespace
      var keyId = CoapKeyId(previous.id);
      _exchangesById.remove(keyId);
    }
  }
}
