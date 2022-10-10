/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/06/2018
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:math';

import '../coap_config.dart';
import '../coap_empty_message.dart';
import '../coap_message.dart';
import '../coap_message_type.dart';
import '../coap_request.dart';
import '../coap_response.dart';
import '../event/coap_event_bus.dart';
import '../net/coap_exchange.dart';
import 'coap_abstract_layer.dart';
import 'coap_ilayer.dart';

/// Transmission context
class CoapTransmissionContext {
  /// Construction
  CoapTransmissionContext(
    this._config,
    this._exchange,
    this._message,
    this._retransmit,
  ) {
    currentTimeout = _message.ackTimeout;
  }

  final DefaultCoapConfig _config;
  final CoapExchange _exchange;
  final CoapMessage _message;

  /// Current timeout
  int currentTimeout = 0;

  /// Failed transmission count
  int failedTransmissionCount = 0;
  Timer? _timer;
  final void Function(CoapTransmissionContext) _retransmit;

  /// Start
  void start() {
    _timer?.cancel();

    if (currentTimeout > 0) {
      _timer = Timer(Duration(milliseconds: currentTimeout), _timerElapsed);
    }
  }

  /// Cancel
  void cancel() {
    _timer!.cancel();
  }

  void _timerElapsed() {
    // Do not retransmit a message if it has been acknowledged,
    // rejected, canceled or already been retransmitted for the maximum
    // number of times.
    if (!_message.isRejected &&
        _message.isActive &&
        failedTransmissionCount <=
            (_message.maxRetransmit != 0
                ? _message.maxRetransmit
                : _config.maxRetransmit)) {
      _message.fireRetransmitting();
      _retransmit(this);
    } else {
      _exchange.timedOut = true;
      _message.isTimedOut = true;
      _exchange.remove(CoapReliabilityLayer.transmissionContextKey);
      final message = CoapEmptyMessage(CoapMessageType.rst)
        ..id = _message.id
        ..token = _message.token;
      _exchange.fireCancel(message);
      cancel();
    }
  }
}

/// The reliability layer
class CoapReliabilityLayer extends CoapAbstractLayer {
  /// Constructs a new reliability layer.
  CoapReliabilityLayer(this._config);

  /// Context key
  static String transmissionContextKey = 'TransmissionContext';

  final DefaultCoapConfig _config;
  final Random _rand = Random();

  /// Schedules a retransmission for confirmable messages.
  @override
  void sendRequest(
    final CoapINextLayer nextLayer,
    final CoapExchange exchange,
    final CoapRequest request,
  ) {
    if (request.type == CoapMessageType.con) {
      _prepareRetransmission(
        exchange,
        request,
        (final ctx) => sendRequest(nextLayer, exchange, request),
      );
    }

    super.sendRequest(nextLayer, exchange, request);
  }

  /// Makes sure that the response type is correct. The response type for a NON
  /// can be NON or CON. The response type for a CON should either be an ACK
  /// with a piggy-backed response or, if an empty ACK has already be sent, a
  /// CON or NON with a separate response.
  @override
  void sendResponse(
    final CoapINextLayer nextLayer,
    final CoapExchange exchange,
    final CoapResponse? response,
  ) {
    final mt = response!.type;
    if (mt == CoapMessageType.ack || mt == CoapMessageType.rst) {
      response.id = exchange.currentRequest!.id;
    }

    if (response.type == CoapMessageType.con) {
      _prepareRetransmission(
        exchange,
        response,
        (final ctx) => sendResponse(nextLayer, exchange, response),
      );
    }

    super.sendResponse(nextLayer, exchange, response);
  }

  /// When we receive a duplicate of a request, we stop it here and do not
  /// forward it to the upper layer. If the server has already sent a response,
  /// we send it again. If the request has only been acknowledged (but the ACK
  /// has gone lost or not reached the client yet), we resent the ACK. If the
  /// request has neither been responded, acknowledged or rejected yet, the
  /// server has not yet decided what to do with the request and we cannot do
  /// anything.
  @override
  void receiveRequest(
    final CoapINextLayer nextLayer,
    final CoapExchange exchange,
    final CoapRequest request,
  ) {
    if (request.duplicate) {
      // Request is a duplicate, so resend ACK, RST or response
      if (exchange.currentResponse != null) {
        super.sendResponse(nextLayer, exchange, exchange.currentResponse!);
      } else if (exchange.currentRequest != null) {
        if (exchange.currentRequest!.isAcknowledged) {
          final ack = CoapEmptyMessage.newACK(request);
          sendEmptyMessage(nextLayer, exchange, ack);
        } else if (exchange.currentRequest!.isRejected) {
          final rst = CoapEmptyMessage.newRST(request);
          sendEmptyMessage(nextLayer, exchange, rst);
        } else {
          // The server has not yet decided, whether to acknowledge or
          // reject the request. We know for sure that the server has
          // received the request though and can drop this duplicate here.
        }
      } else {
        // Lost the current request. The server has not yet decided what to do.
      }
    } else {
      // Request is not a duplicate
      exchange.currentRequest = request;
      super.receiveRequest(nextLayer, exchange, request);
    }
  }

  /// When we receive a Confirmable response, we acknowledge it and it also
  /// counts as acknowledgment for the request. If the response is a duplicate,
  /// we stop it here and do not forward it to the upper layer.
  @override
  void receiveResponse(
    final CoapINextLayer nextLayer,
    final CoapExchange exchange,
    final CoapResponse response,
  ) {
    final ctx =
        exchange.remove(transmissionContextKey) as CoapTransmissionContext?;
    if (ctx != null) {
      exchange.currentRequest!.isAcknowledged = true;
      ctx.cancel();
    }

    if (response.type == CoapMessageType.con &&
        !exchange.request!.isCancelled) {
      final ack = CoapEmptyMessage.newACK(response);
      sendEmptyMessage(nextLayer, exchange, ack);
    }

    if (!response.duplicate) {
      super.receiveResponse(nextLayer, exchange, response);
    }
  }

  /// If we receive an ACK or RST, we mark the outgoing request or response
  /// as acknowledged or rejected respectively and cancel its retransmission.
  @override
  void receiveEmptyMessage(
    final CoapINextLayer nextLayer,
    final CoapExchange exchange,
    final CoapEmptyMessage message,
  ) {
    switch (message.type) {
      case CoapMessageType.ack:
        if (exchange.origin == CoapOrigin.local) {
          exchange.currentRequest!.isAcknowledged = true;
        } else {
          exchange.currentResponse!.isAcknowledged = true;
        }
        break;
      case CoapMessageType.rst:
        if (exchange.origin == CoapOrigin.local) {
          exchange.currentRequest!.isRejected = true;
        } else {
          exchange.currentResponse!.isRejected = true;
        }
        break;
      // ignore: no_default_cases
      default:
        break;
    }

    final ctx =
        exchange.remove(transmissionContextKey) as CoapTransmissionContext?;
    if (ctx != null) {
      ctx.cancel();
    }

    super.receiveEmptyMessage(nextLayer, exchange, message);
  }

  void _prepareRetransmission(
    final CoapExchange exchange,
    final CoapMessage msg,
    final void Function(CoapTransmissionContext) retransmit,
  ) {
    final ctx = exchange.getOrAdd<CoapTransmissionContext>(
      transmissionContextKey,
      CoapTransmissionContext(_config, exchange, msg, retransmit),
    );
    if (ctx != null && ctx.failedTransmissionCount > 0) {
      ctx.currentTimeout =
          (ctx.currentTimeout * _config.ackTimeoutScale).toInt();
    } else if (ctx?.currentTimeout == 0) {
      ctx?.currentTimeout =
          _initialTimeout(_config.ackTimeout, _config.ackRandomFactor);
    }
    ctx?.failedTransmissionCount++;

    exchange.set<CoapTransmissionContext>(transmissionContextKey, ctx!);
    ctx.start();
  }

  int _initialTimeout(final int initialTimeout, final double factor) =>
      (initialTimeout + initialTimeout * (factor - 1.0) * _rand.nextDouble())
          .toInt();
}
