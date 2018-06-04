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
    MessageType mt = response.Type;
    if (mt == MessageType.Unknown) {
      MessageType reqType = exchange.CurrentRequest.Type;
      if (reqType == MessageType.CON) {
        if (exchange.CurrentRequest.IsAcknowledged) {
          // send separate response
          response.Type = MessageType.CON;
        }
        else {
          exchange.CurrentRequest.IsAcknowledged = true;
          // send piggy-backed response
          response.Type = MessageType.ACK;
          response.ID = exchange.CurrentRequest.ID;
        }
      }
      else {
        // send NON response
        response.Type = MessageType.NON;
      }
    }
    else if (mt == MessageType.ACK || mt == MessageType.RST) {
      response.ID = exchange.CurrentRequest.ID;
    }

    if (response.Type == MessageType.CON) {
      if (log.IsDebugEnabled)
        log.Debug("Scheduling retransmission for " + response);
      PrepareRetransmission(
          exchange, response, ctx => SendResponse(nextLayer, exchange,
          response));
    }

    base
        .
    SendResponse
    (
    nextLayer
    ,
    exchange
    ,
    response
    );
  }

  void _prepareRetransmission(CoapExchange exchange, CoapMessage msg,
      ActionGeneric<CoapTransmissionContext> retransmit) {
    CoapTransmissionContext ctx = exchange.getOrAdd<CoapTransmissionContext>(
        transmissionContextKey,
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
