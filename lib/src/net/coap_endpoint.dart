/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// EndPoint encapsulates the stack that executes the CoAP protocol.
class CoapEndPoint extends Object
    with events.EventEmitter, events.EventDetector
    implements CoapIEndPoint, CoapIOutbox {
  /// Instantiates a new endpoint with the
  /// specified channel and configuration.
  CoapEndPoint(CoapIChannel channel, CoapConfig config) {
    _config = config;
    _channel = channel;
    _matcher = new CoapMatcher(config);
    _coapStack = new CoapStack(config);
    listen(_channel, CoapDataReceivedEvent, _receiveData);
  }

  /// Instantiates a new endpoint with internet address, port and configuration
  CoapEndPoint.address(InternetAddress localEndpoint, int port,
      CoapConfig config)
      : this(newUDPChannel(localEndpoint, port), config);

  static CoapILogger _log = new CoapLogManager("console").logger;

  CoapConfig _config;

  CoapConfig get config => _config;
  CoapIChannel _channel;
  CoapStack _coapStack;
  CoapIMessageDeliverer _deliverer;

  set deliverer(CoapIMessageDeliverer value) => _deliverer = value;

  CoapIMessageDeliverer get deliverer =>
      _deliverer != null ? _deliverer : new CoapClientMessageDeliverer();
  CoapIMatcher _matcher;
  InternetAddress _localEndpoint;

  InternetAddress get localEndpoint => _localEndpoint;
  CoapIExecutor executor = new CoapExecutor();

  CoapIOutbox get outbox => this;

  void start() {
    _localEndpoint = _channel.address;
    try {
      _matcher.start();
      _channel.start();
      _localEndpoint = _channel.address;
    } catch (e) {
      _log.error("Cannot start endpoint at $_localEndpoint, exception is $e");
      stop();
      throw e;
    }
    _log.debug("Starting endpoint bound to $_localEndpoint");
  }

  void stop() {
    _log.debug("Stopping endpoint bound to $_localEndpoint");
    _channel.stop();
    _matcher.stop();
    _matcher.clear();
  }

  void clear() {
    _matcher.clear();
  }

  void sendEpRequest(CoapRequest request) {
    //TODO SJH fix this executor.start(() => _coapStack.sendRequest(request));
    _coapStack.sendRequest(request);
  }

  void sendEpResponse(CoapExchange exchange, CoapResponse response) {
    executor.start(() => _coapStack.sendResponse(exchange, response));
  }

  void sendEpEmptyMessage(CoapExchange exchange, CoapEmptyMessage message) {
    executor.start(() => _coapStack.sendEmptyMessage(exchange, message));
  }

  void _receiveData(events.Event<CoapDataReceivedEvent> event) {
    final CoapIMessageDecoder decoder =
    config.spec.newMessageDecoder(event.data.data);
    if (decoder.isRequest) {
      CoapRequest request;
      try {
        request = decoder.decodeRequest();
      } catch (e) {
        if (decoder.isReply) {
          _log.warn("Message format error caused by ${e.endPoint}");
        } else {
          // Manually build RST from raw information
          final CoapEmptyMessage rst =
          new CoapEmptyMessage(CoapMessageType.rst);
          rst.destination = e.endPoint;
          rst.id = decoder.id;
          emitEvent(new CoapSendingEmptyMessageEvent(rst));
          _channel.send(_serializeEmpty(rst), rst.destination);
          _log.warn(
              "Message format error caused by ${e.endPoint} and reseted.");
        }
        return;
      }

      request.source = event.data.address;
      emitEvent(new CoapReceivingRequestEvent(request));

      if (!request.isCancelled) {
        final CoapExchange exchange = _matcher.receiveRequest(request);
        if (exchange != null) {
          exchange.endpoint = this;
          _coapStack.receiveRequest(exchange, request);
        }
      }
    } else if (decoder.isResponse) {
      final CoapResponse response = decoder.decodeResponse();
      response.source = event.data.address;

      emitEvent(new CoapReceivingResponseEvent(response));

      if (!response.isCancelled) {
        final CoapExchange exchange = _matcher.receiveResponse(response);
        if (exchange != null) {
          response.rtt = ((new DateTime.now().difference(exchange.timestamp))
              .inMilliseconds)
              .toDouble();
          exchange.endpoint = this;
          _coapStack.receiveResponse(exchange, response);
        } else if (response.type != CoapMessageType.ack) {
          _log.debug(
              "Rejecting unmatchable response from ${event.data.address}");
          _reject(response);
        }
      }
    } else if (decoder.isEmpty) {
      final CoapEmptyMessage message = decoder.decodeEmptyMessage();
      message.source = event.data.address;

      emitEvent(new CoapReceivingEmptyMessageEvent(message));

      if (!message.isCancelled) {
        // CoAP Ping
        if (message.type == CoapMessageType.con ||
            message.type == CoapMessageType.non) {
          _log.debug("Responding to ping by ${event.data.address}");
          _reject(message);
        } else {
          final CoapExchange exchange = _matcher.receiveEmptyMessage(message);
          if (exchange != null) {
            exchange.endpoint = this;
            _coapStack.receiveEmptyMessage(exchange, message);
          }
        }
      }
    } else {
      _log.debug(
          "Silently ignoring non-CoAP message from ${event.data.address}");
    }
  }

  void sendRequest(CoapExchange exchange, CoapRequest request) {
    _matcher.sendRequest(exchange, request);
    emitEvent(new CoapSendingRequestEvent(request));

    if (!request.isCancelled) {
      _channel.send(_serializeRequest(request), request.destination);
    }
  }

  void sendResponse(CoapExchange exchange, CoapResponse response) {
    _matcher.sendResponse(exchange, response);
    emitEvent(new CoapSendingResponseEvent(response));

    if (!response.isCancelled) {
      _channel.send(_serializeResponse(response), response.destination);
    }
  }

  void sendEmptyMessage(CoapExchange exchange, CoapEmptyMessage message) {
    _matcher.sendEmptyMessage(exchange, message);
    emitEvent(new CoapSendingEmptyMessageEvent(message));

    if (!message.isCancelled) {
      _channel.send(_serializeEmpty(message), message.destination);
    }
  }

  void _reject(CoapMessage message) {
    final CoapEmptyMessage rst = CoapEmptyMessage.newRST(message);
    emitEvent(new CoapSendingEmptyMessageEvent(rst));

    if (!rst.isCancelled) {
      _channel.send(_serializeEmpty(rst), rst.destination);
    }
  }

  typed.Uint8Buffer _serializeEmpty(CoapEmptyMessage message) {
    typed.Uint8Buffer bytes = message.bytes;
    if (bytes == null) {
      bytes = _config.spec.newMessageEncoder().encodeMessage(message);
      message.bytes = bytes;
    }
    return bytes;
  }

  typed.Uint8Buffer _serializeRequest(CoapMessage message) {
    typed.Uint8Buffer bytes = message.bytes;
    if (bytes == null) {
      bytes = _config.spec.newMessageEncoder().encodeMessage(message);
      message.bytes = bytes;
    }
    return bytes;
  }

  typed.Uint8Buffer _serializeResponse(CoapMessage message) {
    typed.Uint8Buffer bytes = message.bytes;
    if (bytes == null) {
      bytes = _config.spec.newMessageEncoder().encodeMessage(message);
      message.bytes = bytes;
    }
    return bytes;
  }

  static CoapIChannel newUDPChannel(InternetAddress localEndpoint, int port) {
    final CoapIChannel channel = new CoapUDPChannel(localEndpoint, port);
    return channel;
  }
}
