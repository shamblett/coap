/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2018
 * Copyright :  S.Hamblett
 */

import 'dart:async';

import '../../coap_config.dart';
import '../../coap_empty_message.dart';
import '../../coap_message_type.dart';
import '../../coap_request.dart';
import '../../coap_response.dart';
import '../../event/coap_event_bus.dart';
import '../../net/exchange.dart';
import '../../option/integer_option.dart';
import '../base_layer.dart';

/// Observe layer
class ObserveLayer extends BaseLayer {
  /// Constructs a new observe layer.
  ObserveLayer(final DefaultCoapConfig config) {
    _backoff = config.notificationReregistrationBackoff;
  }

  /// Context key
  static String reregistrationContextKey = 'ReregistrationContext';

  /// Additional time to wait until re-registration
  late int _backoff;

  @override
  void sendResponse(
    final CoapExchange initialExchange,
    final CoapResponse response,
  ) {
    final exchange = initialExchange;

    final relation = exchange.relation;
    if (relation != null && relation.established) {
      if (exchange.request!.isAcknowledged ||
          exchange.request!.type == CoapMessageType.non) {
        // Transmit errors as CON
        if (!response.isSuccess) {
          response.type = CoapMessageType.con;
          relation.cancel();
        } else {
          // Make sure that every now and than a CON is mixed within
          if (relation.check()) {
            response.type = CoapMessageType.con;
          }
        }
      }

      // This is a notification
      response.last = false;

      // The matcher must be able to find the NON notifications to remove
      // them from the exchangesByID map
      if (response.type == CoapMessageType.non) {
        relation.addNotification(response);
      }
      // Only one Confirmable message is allowed to be in transit. A CON
      // is in transit as long as it has not been acknowledged, rejected,
      // or timed out. All further notifications are postponed here. If a
      // former CON is acknowledged or timeouts, it starts the freshest
      // notification (In case of a timeout, it keeps the retransmission
      //  counter). When a fresh/younger notification arrives but must be
      //  postponed we forget any former notification.

      if (response.type == CoapMessageType.con) {
        _prepareSelfReplacement(exchange, response);
      }

      // The decision whether to postpone this notification or not and the
      // decision which notification is the freshest to send next must be
      // synchronized
      final current = relation.currentControlNotification;
      if (current != null && _isInTransit(current)) {
        // use the same ID
        response.id = current.id;
        relation.nextControlNotification = response;
        return;
      } else {
        relation
          ..currentControlNotification = response
          ..nextControlNotification = null;
      }
    }
    // Else no observe was requested or the resource does not allow it
    super.sendResponse(exchange, response);
  }

  @override
  void receiveResponse(
    final CoapExchange initialExchange,
    final CoapResponse response,
  ) {
    final exchange = initialExchange;

    if (response.hasOption<ObserveOption>()) {
      if (exchange.request!.isCancelled) {
        // The request was canceled and we no longer want notifications
        final rst = CoapEmptyMessage.newRST(response);
        // Matcher sets exchange as complete when RST is sent
        sendEmptyMessage(exchange, rst);
        _prepareReregistration(
          exchange,
          response,
          (final msg) => sendRequest(exchange, msg),
        );
      } else {
        super.receiveResponse(exchange, response);
      }
    } else {
      // No observe option in response => always deliver
      super.receiveResponse(exchange, response);
    }
  }

  @override
  void receiveEmptyMessage(
    final CoapExchange initialExchange,
    final CoapEmptyMessage message,
  ) {
    final exchange = initialExchange;
    // NOTE: We could also move this into the MessageObserverAdapter from
    // sendResponse into the method rejected().
    if (message.type == CoapMessageType.rst &&
        exchange.origin == CoapOrigin.remote) {
      // The response has been rejected
      final relation = exchange.relation;
      if (relation != null) {
        relation.cancel();
      } // Else there was no observe relation ship and this
      // layer ignores the rst.
    }
    super.receiveEmptyMessage(exchange, message);
  }

  static bool _isInTransit(final CoapResponse response) {
    final type = response.type;
    final acked = response.isAcknowledged;
    final timeout = response.isTimedOut;
    final result = type == CoapMessageType.con && !acked && !timeout;
    return result;
  }

  void _prepareSelfReplacement(
    final CoapExchange exchange,
    final CoapResponse response,
  ) {
    response
      ..acknowledgedHook = () {
        final relation = exchange.relation!;
        final next = relation.nextControlNotification;
        relation
          ..currentControlNotification = next // next may be null
          ..nextControlNotification = null;
        if (next != null) {
          // this is not a self replacement, hence a new ID
          next.id = null;
          sendResponse(exchange, next);
        }
      }
      ..retransmittingHook = () {
        final relation = exchange.relation!;
        final next = relation.nextControlNotification;
        if (next != null) {
          // Cancel the original retransmission and send the fresh
          // notification here.
          response.isCancelled = true;
          // Use the same ID
          next.id = response.id;
          // Convert all notification retransmissions to CON
          if (next.type != CoapMessageType.con) {
            next.type = CoapMessageType.con;
            _prepareSelfReplacement(exchange, next);
          }
          relation
            ..currentControlNotification = next
            ..nextControlNotification = null;
          sendResponse(exchange, next);
        }
      }
      ..timedOutHook = () {
        exchange.relation!.cancelAll();
      };
  }

  void _prepareReregistration(
    final CoapExchange exchange,
    final CoapResponse response,
    final void Function(CoapRequest) reregister,
  ) {
    final timeout = response.maxAge * 1000 + _backoff;
    exchange
        .getOrAdd<_ReregistrationContext>(
          reregistrationContextKey,
          _ReregistrationContext(exchange, timeout, reregister),
        )!
        .restart();
  }
}

/// Registration context
class _ReregistrationContext {
  /// Construction
  _ReregistrationContext(this._exchange, this._timeout, this._reregister);

  final CoapExchange _exchange;
  final void Function(CoapRequest) _reregister;
  Timer? _timer;
  final int _timeout;

  /// Start
  void start() {
    _timer = Timer(Duration(milliseconds: _timeout), _timerElapsed);
  }

  /// Restart
  void restart() {
    cancel();
    _timer = Timer(Duration(milliseconds: _timeout), _timerElapsed);
  }

  /// Cancel
  void cancel() {
    _timer?.cancel();
  }

  void _timerElapsed() {
    final request = _exchange.request!;
    if (!request.isCancelled) {
      final refresh = CoapRequest.newGet()
        ..setOptions(request.getAllOptions())
        // Make sure Observe is set and zero
        ..observe = 0
        // Use same Token
        ..token = request.token
        ..destination = request.destination
        ..copyEventHandler(request);
      _exchange.fireReregistering(refresh);
      _reregister(refresh);
    }
  }
}
