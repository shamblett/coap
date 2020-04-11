/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/06/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Transmission context
class CoapTransmissionContext {
  /// Construction
  CoapTransmissionContext(
      this._config, this._exchange, this._message, this._retransmit) {
    currentTimeout = _message.ackTimeout;
  }

  final CoapILogger _log = CoapLogManager().logger;
  final DefaultCoapConfig _config;
  final CoapExchange _exchange;
  final CoapMessage _message;

  /// Current timeout
  int currentTimeout = 0;

  /// Failed transmission count
  int failedTransmissionCount = 0;
  Timer _timer;
  final ActionGeneric<CoapTransmissionContext> _retransmit;

  /// Start
  void start() {
    _timer?.cancel();

    if (currentTimeout > 0) {
      _log.info('Reliability - Retransmission timeout is $currentTimeout ms');
      _timer = Timer(Duration(milliseconds: currentTimeout), _timerElapsed);
    }
  }

  /// Cancel
  void cancel() {
    _timer.cancel();
    if (_exchange.origin == CoapOrigin.local) {
      _log.info('Reliability - Cancel retransmission for token: '
          '${_exchange.currentRequest.tokenString} id: '
          '${_exchange.currentRequest.id}');
    } else {
      _log.info('Reliability - Cancel retransmission for token: '
          '${_exchange.currentResponse.tokenString} id: '
          '${_exchange.currentResponse.id}');
    }
  }

  void _timerElapsed() {
    // Do not retransmit a message if it has been acknowledged,
    // rejected, canceled or already been retransmitted for the maximum
    // number of times.
    _log.warn('Reliability - Retransmission timeout elapsed');
    final failedCount = ++failedTransmissionCount;

    if (_message.isAcknowledged) {
      _log.info('Reliability - Timeout: message already acknowledged, cancel '
          'retransmission of $_message');
      _exchange.timedOut = true;
      _message.isTimedOut = true;
      _exchange.remove(CoapReliabilityLayer.transmissionContextKey);
      cancel();
      return;
    } else if (_message.isRejected) {
      _log.info('Reliability - Timeout: message already rejected, '
          'cancel retransmission of _message');
      _exchange.timedOut = true;
      _message.isTimedOut = true;
      _exchange.remove(CoapReliabilityLayer.transmissionContextKey);
      cancel();
      return;
    } else if (_message.isCancelled) {
      _log.info('Reliability - Timeout: message ${_message.id} cancelled');
      _exchange.timedOut = true;
      _message.isTimedOut = true;
      _exchange.remove(CoapReliabilityLayer.transmissionContextKey);
      cancel();
      return;
    } else if (failedCount <=
        (_message.maxRetransmit != 0
            ? _message.maxRetransmit
            : _config.maxRetransmit)) {
      _log.warn('Reliability - Timeout: retransmit message, failed count: '
          '$failedCount message: ${_message.id}');

      // Message might have canceled
      if (_message.isCancelled || _message.maxRetransmit == CoapMessage.none) {
        _log.warn('Reliability - not retransmitting, message is cancelled or '
            'is set to no retransmit');
      } else {
        _message.fireRetransmitting();
        _retransmit(this);
      }
    } else {
      _log.warn('Reliability - Timeout: retransmission limit reached, '
          'exchange failed, message: ${_message.id}');
      _exchange.timedOut = true;
      _message.isTimedOut = true;
      _exchange.remove(CoapReliabilityLayer.transmissionContextKey);
      cancel();
    }
  }
}

/// The reliability layer
class CoapReliabilityLayer extends CoapAbstractLayer {
  /// Constructs a new reliability layer.
  CoapReliabilityLayer(DefaultCoapConfig config) {
    _config = config;
  }

  final CoapILogger _log = CoapLogManager().logger;

  /// Context key
  static String transmissionContextKey = 'TransmissionContext';

  DefaultCoapConfig _config;
  final Random _rand = Random();

  /// Schedules a retransmission for confirmable messages.
  @override
  void sendRequest(
      CoapINextLayer nextLayer, CoapExchange exchange, CoapRequest request) {
    if (request.type == CoapMessageType.unknown) {
      request.type = CoapMessageType.con;
    }

    if (request.type == CoapMessageType.con) {
      _log.info('Reliability - Scheduling transmission for $request');
      _prepareRetransmission(exchange, request,
          (dynamic ctx) => sendRequest(nextLayer, exchange, request));
    }

    super.sendRequest(nextLayer, exchange, request);
  }

  /// Makes sure that the response type is correct. The response type for a NON
  /// can be NON or CON. The response type for a CON should either be an ACK
  /// with a piggy-backed response or, if an empty ACK has already be sent, a
  /// CON or NON with a separate response.
  @override
  void sendResponse(
      CoapINextLayer nextLayer, CoapExchange exchange, CoapResponse response) {
    final mt = response.type;
    if (mt == CoapMessageType.unknown) {
      final reqType = exchange.currentRequest.type;
      if (reqType == CoapMessageType.con) {
        if (exchange.currentRequest.isAcknowledged) {
          // Send separate response
          response.type = CoapMessageType.con;
        } else {
          exchange.currentRequest.isAcknowledged = true;
          // send piggy-backed response
          response.type = CoapMessageType.ack;
          response.id = exchange.currentRequest.id;
        }
      } else {
        // send NON response
        response.type = CoapMessageType.non;
      }
    } else if (mt == CoapMessageType.ack || mt == CoapMessageType.rst) {
      response.id = exchange.currentRequest.id;
    }

    if (response.type == CoapMessageType.con) {
      _log.info('Reliability - Scheduling retransmission for $response');
      _prepareRetransmission(exchange, response,
          (dynamic ctx) => sendResponse(nextLayer, exchange, response));
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
      CoapINextLayer nextLayer, CoapExchange exchange, CoapRequest request) {
    if (request.duplicate) {
      // Request is a duplicate, so resend ACK, RST or response
      if (exchange.currentResponse != null) {
        _log.info('Respond with the current response to the duplicate request');
        super.sendResponse(nextLayer, exchange, exchange.currentResponse);
      } else if (exchange.currentRequest != null) {
        if (exchange.currentRequest.isAcknowledged) {
          _log.info('The duplicate request was acknowledged but no response '
              'computed yet. Retransmit ACK.');
          final ack = CoapEmptyMessage.newACK(request);
          sendEmptyMessage(nextLayer, exchange, ack);
        } else if (exchange.currentRequest.isRejected) {
          _log.info('The duplicate request was rejected. Reject again.');
          final rst = CoapEmptyMessage.newRST(request);
          sendEmptyMessage(nextLayer, exchange, rst);
        } else {
          _log.info('Reliability - The server has not yet decided what to do '
              'with the request. Ignoring the duplicate.');
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
      CoapINextLayer nextLayer, CoapExchange exchange, CoapResponse response) {
    final CoapTransmissionContext ctx = exchange.remove(transmissionContextKey);
    if (ctx != null) {
      exchange.currentRequest.isAcknowledged = true;
      ctx.cancel();
    }

    if (response.type == CoapMessageType.con && !exchange.request.isCancelled) {
      _log.info('Reliability - Response is confirmable, send ACK.');
      final ack = CoapEmptyMessage.newACK(response);
      sendEmptyMessage(nextLayer, exchange, ack);
    }

    if (response.duplicate) {
      _log.info('Reliability - Response is duplicate, ignoring.');
    } else {
      super.receiveResponse(nextLayer, exchange, response);
    }
  }

  /// If we receive an ACK or RST, we mark the outgoing request or response
  /// as acknowledged or rejected respectively and cancel its retransmission.
  @override
  void receiveEmptyMessage(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapEmptyMessage message) {
    switch (message.type) {
      case CoapMessageType.ack:
        if (exchange.origin == CoapOrigin.local) {
          exchange.currentRequest.isAcknowledged = true;
        } else {
          exchange.currentResponse.isAcknowledged = true;
        }
        break;
      case CoapMessageType.rst:
        if (exchange.origin == CoapOrigin.local) {
          exchange.currentRequest.isRejected = true;
        } else {
          exchange.currentResponse.isRejected = true;
        }
        break;
      default:
        _log.warn('Reliability - Empty messgae was not ACK nor RST: $message');
        break;
    }

    final CoapTransmissionContext ctx = exchange.remove(transmissionContextKey);
    if (ctx != null) {
      ctx.cancel();
    }

    super.receiveEmptyMessage(nextLayer, exchange, message);
  }

  void _prepareRetransmission(CoapExchange exchange, CoapMessage msg,
      ActionGeneric<CoapTransmissionContext> retransmit) {
    final ctx = exchange.getOrAdd<CoapTransmissionContext>(
        transmissionContextKey,
        CoapTransmissionContext(_config, exchange, msg, retransmit));

    if (ctx.failedTransmissionCount > 0) {
      ctx.currentTimeout =
          (ctx.currentTimeout * _config.ackTimeoutScale).toInt();
    } else if (ctx.currentTimeout == 0) {
      ctx.currentTimeout =
          _initialTimeout(_config.ackTimeout, _config.ackRandomFactor);
    }

    if (ctx.failedTransmissionCount > 0) {
      _log.debug('Reliability - sending request, failed transmission count: '
          '${ctx.failedTransmissionCount}');
    } else {
      _log.info('Reliability - sending request, failed transmission count: '
          '${ctx.failedTransmissionCount}');
    }

    ctx.start();
  }

  int _initialTimeout(int initialTimeout, double factor) =>
      (initialTimeout + initialTimeout * (factor - 1.0) * _rand.nextDouble())
          .toInt();
}
