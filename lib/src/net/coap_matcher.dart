/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/05/2018
 * Copyright :  S.Hamblett
 */

import 'dart:async';

import '../coap_config.dart';
import '../coap_empty_message.dart';
import '../coap_message_type.dart';
import '../coap_option_type.dart';
import '../coap_request.dart';
import '../coap_response.dart';
import '../deduplication/coap_deduplicator_factory.dart';
import '../deduplication/coap_ideduplicator.dart';
import '../event/coap_event_bus.dart';
import '../observe/coap_observe_relation.dart';
import 'coap_exchange.dart';
import 'coap_imatcher.dart';
import 'coap_multicast_exchange.dart';

/// Matcher class
class CoapMatcher implements CoapIMatcher {
  /// Construction
  CoapMatcher(final DefaultCoapConfig config, {required this.namespace}) {
    _eventBus = CoapEventBus(namespace: namespace);
    _deduplicator = CoapDeduplicatorFactory.createDeduplicator(config);
    subscr = _eventBus.on<CoapCompletedEvent>().listen(onExchangeCompleted);
  }

  late final CoapEventBus _eventBus;
  final String namespace;
  late StreamSubscription<CoapCompletedEvent> subscr;

  /// For all
  final Map<int?, CoapExchange> _exchangesById = <int?, CoapExchange>{};

  /// For outgoing
  final Map<String, CoapExchange> _exchangesByToken = <String, CoapExchange>{};

  /// For blockwise
  final Map<String, CoapExchange> _ongoingExchanges = <String, CoapExchange>{};

  late final CoapIDeduplicator _deduplicator;

  @override
  void start() {
    _deduplicator.start();
  }

  @override
  void stop() {
    _deduplicator.stop();
    subscr.cancel();
  }

  @override
  void clear() {
    _exchangesById.clear();
    _exchangesByToken.clear();
    _ongoingExchanges.clear();
    _deduplicator.clear();
  }

  @override
  void sendRequest(final CoapExchange exchange, final CoapRequest request) {
    // The request is a CON or NON and must be prepared for these responses
    // - CON => ACK / RST / ACK+response / CON+response / NON+response
    // - NON => RST / CON+response / NON+response
    // If this request goes lost, we do not get anything back.

    // The MID is from the local namespace -- use blank address
    _exchangesById[request.id] = exchange;
    _exchangesByToken[request.tokenString] = exchange;
  }

  @override
  void sendResponse(final CoapExchange exchange, final CoapResponse response) {
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

    // Blockwise transfers are identified by token
    if (response.hasOption(OptionType.block2)) {
      final request = exchange.currentRequest!;
      // Observe notifications only send the first block,
      // hence do not store them as ongoing.
      if (exchange.responseBlockStatus != null &&
          !response.hasOption(OptionType.observe)) {
        // Remember ongoing blockwise GET requests
        _ongoingExchanges[request.tokenString] = exchange;
      } else {
        _ongoingExchanges.remove(request.tokenString);
      }
    }

    // Insert CON and NON to match ACKs and RSTs to the exchange
    // Do not insert ACKs and RSTs.
    if (response.type == CoapMessageType.con ||
        response.type == CoapMessageType.non) {
      _exchangesById[response.id] = exchange;
    }

    // Only CONs and Observe keep the exchange active
    if (response.type != CoapMessageType.con && response.last) {
      exchange.complete = true;
    }
  }

  @override
  void sendEmptyMessage(
    final CoapExchange exchange,
    final CoapEmptyMessage message,
  ) {
    if (message.type == CoapMessageType.rst) {
      // We have rejected the request or response
      exchange.complete = true;
    }
  }

  @override
  CoapExchange receiveRequest(final CoapRequest request) {
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

    // The differentiation between the case where there is a Block1 or
    // Block2 option and the case where there is none has the advantage that
    // all exchanges that do not need blockwise transfer have simpler and
    // faster code than exchanges with blockwise transfer.

    if (!request.hasOption(OptionType.block1) &&
        !request.hasOption(OptionType.block2)) {
      final exchange =
          CoapExchange(request, CoapOrigin.remote, namespace: namespace);
      final previous = _deduplicator.findPrevious(request.id, exchange);
      if (previous == null) {
        return exchange;
      } else {
        request.duplicate = true;
        return previous;
      }
    } else {
      final ongoing = _ongoingExchanges[request.tokenString];
      if (ongoing != null) {
        final prev = _deduplicator.findPrevious(request.id, ongoing);
        if (prev != null) {
          request.duplicate = true;
        } else {
          // The exchange is continuing, we can (i.e., must)
          // clean up the previous response.
          if (ongoing.currentResponse!.type != CoapMessageType.ack &&
              !ongoing.currentResponse!.hasOption(OptionType.observe)) {
            _exchangesById.remove(ongoing.currentResponse!.id);
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

        final exchange =
            CoapExchange(request, CoapOrigin.remote, namespace: namespace);
        final previous = _deduplicator.findPrevious(request.id, exchange);
        if (previous == null) {
          _ongoingExchanges[request.tokenString] = exchange;
          return exchange;
        } else {
          request.duplicate = true;
          return previous;
        }
      } // if ongoing
    } // if blockwise
  }

  @override
  CoapExchange? receiveResponse(final CoapResponse response) {
    // This response could be
    // The first CON/NON/ACK+response => deliver
    // Retransmitted CON (because client got no ACK)
    //	=> resend ACK
    final exchange = _exchangesByToken[response.tokenString];
    if (exchange != null) {
      if (exchange is CoapMulticastExchange) {
        if (!exchange.alreadyReceived(response)) {
          exchange.responses.add(response);
        } else {
          response.duplicate = true;
        }
        return exchange;
      }

      // There is an exchange with the given token
      final prev = _deduplicator.findPrevious(response.id, exchange);
      if (prev != null) {
        response.duplicate = true;
      } else {
        _exchangesById.remove(exchange.currentRequest!.id);
      }

      return exchange;
    } else {
      // There is no exchange with the given token.
      if (response.type != CoapMessageType.ack) {
        // Only act upon separate responses
        final prev = _deduplicator.find(response.id);
        if (prev != null) {
          response.duplicate = true;
          return prev;
        }
      }
      // Ignore response
      return null;
    }
  }

  @override
  CoapExchange? receiveEmptyMessage(final CoapEmptyMessage message) {
    // Local namespace
    final exchange = _exchangesById[message.id];
    if (exchange != null) {
      _exchangesById.remove(message.id);
      return exchange;
    }
    return null;
  }

  /// Exchange completed event handler
  void onExchangeCompleted(final CoapCompletedEvent event) {
    final exchange = event.exchange;

    if (exchange.origin == CoapOrigin.local) {
      // This endpoint created the Exchange by issuing a request
      _exchangesByToken.remove(exchange.currentRequest!.tokenString);
      // In case an empty ACK was lost
      _exchangesById.remove(exchange.currentRequest!.id);
    } else // Origin.Remote
    {
      // This endpoint created the Exchange to respond a request
      final response = exchange.currentResponse;
      if (response != null && response.type != CoapMessageType.ack) {
        // Only response MIDs are stored for ACK and RST, no reponse Tokens
        _exchangesById.remove(response.id);
      }

      final request = exchange.currentRequest;
      if (request != null &&
          (request.hasOption(OptionType.block1) ||
              (response != null && response.hasOption(OptionType.block2)))) {
        _ongoingExchanges.remove(request.tokenString);
      }

      // Remove all remaining NON-notifications if this exchange is
      // an observe relation.
      final relation = exchange.relation;
      if (relation != null) {
        _removeNotificatoinsOf(relation);
      }
    }
  }

  void _removeNotificatoinsOf(final CoapObserveRelation relation) {
    for (final previous in relation.clearNotifications()) {
      // Notifications are local MID namespace
      _exchangesById.remove(previous!.id);
    }
  }
}
