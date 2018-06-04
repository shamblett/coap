/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/06/2018
 * Copyright :  S.Hamblett
 */

part of coap;

class CoapTransmissionContext {
  CoapTransmissionContext(CoapConfig config, CoapExchange exchange,
      CoapMessage message, ActionGeneric<CoapTransmissionContext> retransmit) {
    _config = config;
    _exchange = exchange;
    _message = message;
    _retransmit = retransmit;
    _currentTimeout = message.ackTimeout;
  }

  static CoapILogger _log = new CoapLogManager("console").logger;
  CoapConfig _config;
  CoapExchange _exchange;
  CoapMessage _message;
  int _currentTimeout;
  int _failedTransmissionCount;
  Timer _timer;
  ActionGeneric<CoapTransmissionContext> _retransmit;
  int failedTransmissionCount;
  int currentTimeout;

  void start() {
    _timer.cancel();

    if (_currentTimeout > 0) {
      _timer = new Timer(
          new Duration(milliseconds: _currentTimeout), () => _timerElapsed());
    }
  }

  void cancel() {
    _timer.cancel();

    _log.debug("Cancel retransmission for -->");
    if (_exchange.origin == CoapOrigin.local) {
      _log.debug(_exchange.currentRequest.toString());
    } else {
      _log.debug(_exchange.currentResponse.toString());
    }
  }

  void _timerElapsed() {
    // Do not retransmit a message if it has been acknowledged,
    // rejected, canceled or already been retransmitted for the maximum
    // number of times.

    final int failedCount = ++_failedTransmissionCount;

    if (_message.isAcknowledged) {
      _log.debug(
          "Timeout: message already acknowledged, cancel retransmission of $_message");
      return;
    } else if (_message.isRejected) {
      _log.debug(
          "Timeout: message already rejected, cancel retransmission of _message");
      return;
    } else if (_message.isCancelled) {
      _log.debug("Timeout: canceled (ID= ${_message.id} do not retransmit");
      return;
    } else if (failedCount <=
        (_message.maxRetransmit != 0
            ? _message.maxRetransmit
            : _config.maxRetransmit)) {
      _log.debug(
          "Timeout: retransmit message, failed: $failedCount message: $_message");

      _message.fireRetransmitting();

// Message might have canceled
      if (!_message.isCancelled) _retransmit(this);
    } else {
      _log.debug(
          "Timeout: retransmission limit reached, exchange failed, message: $_message");
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
  CoapReliabilityLayer(CoapConfig config) {
    _config = config;
  }

  static CoapILogger _log = new CoapLogManager("console").logger;
  static String transmissionContextKey = "TransmissionContext";

  CoapConfig _config;
  Random _rand = new Random();

  /// Schedules a retransmission for confirmable messages.
  /// @override
  void sendRequest(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapRequest request) {
    if (request.type == CoapMessageType.unknown) {
      request.type = CoapMessageType.con;
    }

    if (request.type == CoapMessageType.con) {
      _log.debug("Scheduling retransmission for $request");
      _prepareRetransmission(exchange, request,
              (ctx) => sendRequest(nextLayer, exchange, request));
    }

    super.sendRequest(nextLayer, exchange, request);
  }

  /// Makes sure that the response type is correct. The response type for a NON
  /// can be NON or CON. The response type for a CON should either be an ACK
  /// with a piggy-backed response or, if an empty ACK has already be sent, a
  /// CON or NON with a separate response.
  @override
  void sendResponse(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapResponse response) {
    final int mt = response.type;
    if (mt == CoapMessageType.unknown) {
      final int reqType = exchange.currentRequest.type;
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
      _log.debug("Scheduling retransmission for $response");
      _prepareRetransmission(exchange, response,
              (ctx) => sendResponse(nextLayer, exchange, response));
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
  void receiveRequest(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapRequest request) {
    if (request.duplicate) {
      // Request is a duplicate, so resend ACK, RST or response
      if (exchange.currentResponse != null) {
        _log.debug(
            "Respond with the current response to the duplicate request");
        super.sendResponse(nextLayer, exchange, exchange.currentResponse);
      } else if (exchange.currentRequest != null) {
        if (exchange.currentRequest.isAcknowledged) {
          _log.debug(
              "The duplicate request was acknowledged but no response computed yet. Retransmit ACK.");
          final CoapEmptyMessage ack = CoapEmptyMessage.newACK(request);
          sendEmptyMessage(nextLayer, exchange, ack);
        } else if (exchange.currentRequest.isRejected) {
          _log.debug("The duplicate request was rejected. Reject again.");
          final CoapEmptyMessage rst = CoapEmptyMessage.newRST(request);
          sendEmptyMessage(nextLayer, exchange, rst);
        } else {
          _log.debug(
              "The server has not yet decided what to do with the request. We ignore the duplicate.");
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
  void receiveResponse(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapResponse response) {
    final CoapTransmissionContext ctx =
    exchange.remove(transmissionContextKey) as CoapTransmissionContext;
    if (ctx != null) {
      exchange.currentRequest.isAcknowledged = true;
      ctx.cancel();
    }

    if (response.type == CoapMessageType.con && !exchange.request.isCancelled) {
      _log.debug("Response is confirmable, send ACK.");
      final CoapEmptyMessage ack = CoapEmptyMessage.newACK(response);
      sendEmptyMessage(nextLayer, exchange, ack);
    }

    if (response.duplicate) {
      _log.debug("Response is duplicate, ignore it.");
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
        _log.warn("Empty messgae was not ACK nor RST: $message");
        break;
    }

    final CoapTransmissionContext ctx =
    exchange.remove(transmissionContextKey) as CoapTransmissionContext;
    if (ctx != null) ctx.cancel();

    super.receiveEmptyMessage(nextLayer, exchange, message);
  }

  void _prepareRetransmission(CoapExchange exchange, CoapMessage msg,
      ActionGeneric<CoapTransmissionContext> retransmit) {
    final CoapTransmissionContext ctx = exchange.getOrAdd<
        CoapTransmissionContext>(transmissionContextKey,
            () =>
        new CoapTransmissionContext(_config, exchange, msg, retransmit));

    if (ctx.failedTransmissionCount > 0) {
      ctx.currentTimeout =
          (ctx.currentTimeout * _config.ackTimeoutScale).toInt();
    } else if (ctx.currentTimeout == 0) {
      ctx.currentTimeout =
          _initialTimeout(_config.ackTimeout, _config.ackRandomFactor);
    }

    _log.debug(
        "Send request, failed transmissions: $ctx.failedTransmissionCount");

    ctx.start();
  }

  int _initialTimeout(int initialTimeout, double factor) {
    return (initialTimeout +
        initialTimeout * (factor - 1.0) * _rand.nextDouble())
        .toInt();
  }
}
