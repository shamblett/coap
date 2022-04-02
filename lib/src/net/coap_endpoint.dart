/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// EndPoint encapsulates the stack that executes the CoAP protocol.
class CoapEndPoint implements CoapIEndPoint, CoapIOutbox {
  /// Instantiates a new endpoint with the
  /// specified channel and configuration.
  CoapEndPoint(CoapIChannel channel, this._config,
      {required String namespace}) {
    _channel = channel;
    _eventBus = CoapEventBus(namespace: namespace);
    _matcher = CoapMatcher(config, namespace: namespace);
    _coapStack = CoapStack(config);
    subscr = _eventBus.on<CoapDataReceivedEvent>().listen(_receiveData);
  }

  /// Instantiates a new endpoint with internet address, port and configuration
  CoapEndPoint.address(String scheme, CoapInternetAddress localEndpoint,
      int port, DefaultCoapConfig config, {required String namespace})
      : this(
            CoapEndpointManager.determineCoapChannel(
                scheme, localEndpoint, port,
                namespace: namespace, config: config),
            config,
            namespace: namespace);

  final CoapILogger? _log = CoapLogManager().logger;
  late final CoapEventBus _eventBus;

  DefaultCoapConfig _config;

  @override
  DefaultCoapConfig get config => _config;
  late CoapIChannel _channel;
  late CoapStack _coapStack;
  StreamSubscription? subscr;

  @override
  CoapIMessageDeliverer? deliverer = CoapClientMessageDeliverer();

  late CoapIMatcher _matcher;
  CoapInternetAddress? _localEndpoint;

  @override
  CoapInternetAddress? get localEndpoint => _localEndpoint;

  /// Executor
  CoapIExecutor executor = CoapExecutor();

  @override
  CoapIOutbox get outbox => this;

  @override
  Future<void> start() async {
    _localEndpoint = _channel.address;
    try {
      _matcher.start();
      await _channel.start();
      _localEndpoint = _channel.address;
    } on Exception catch (e) {
      _log!.error('Cannot start endpoint at ${_localEndpoint!.address}, '
          'exception is $e');
      stop();
      rethrow;
    }
    _log!.info('Starting endpoint bound to ${_localEndpoint!.address}');
  }

  @override
  void stop() {
    _log!.info(
        'Endpoint - stopping endpoint bound to ${_localEndpoint!.address}');
    _channel.stop();
    _matcher.stop();
    subscr?.cancel();
  }

  @override
  void clear() {
    _matcher.clear();
  }

  @override
  void sendEpRequest(CoapRequest request) {
    executor.start(() => _coapStack.sendRequest(request));
  }

  @override
  void sendEpResponse(CoapExchange exchange, CoapResponse? response) {
    executor.start(() => _coapStack.sendResponse(exchange, response));
  }

  @override
  void sendEpEmptyMessage(CoapExchange exchange, CoapEmptyMessage message) {
    executor.start(() => _coapStack.sendEmptyMessage(exchange, message));
  }

  void _receiveData(CoapDataReceivedEvent event) {
    // clone the data, in case other objects want to do stuff with it, too
    final data = typed.Uint8Buffer();
    data.addAll(event.data);
    // Return if we have no data, should not happen but be defensive
    final decoder = config.spec!.newMessageDecoder(data);
    if (decoder.isRequest) {
      CoapRequest? request;
      try {
        request = decoder.decodeRequest();
      } on Exception catch (e) {
        if (decoder.isReply) {
          _log!.warn('Message format error caused by $e');
        } else {
          // Manually build RST from raw information
          final rst = CoapEmptyMessage(CoapMessageType.rst);
          rst.destination = event.address;
          rst.id = decoder.id;
          _eventBus.fire(CoapSendingEmptyMessageEvent(rst));
          _channel.send(_serializeEmpty(rst), rst.destination);
          _log!.warn('Message format error caused by $e and reset.');
        }
        return;
      }

      request!.source = event.address;
      _eventBus.fire(CoapReceivingRequestEvent(request));

      if (!request.isCancelled) {
        final exchange = _matcher.receiveRequest(request);
        exchange.endpoint = this;
        _coapStack.receiveRequest(exchange, request);
      }
    } else if (decoder.isResponse) {
      final response = decoder.decodeResponse()!;
      response.source = event.address;

      _eventBus.fire(CoapReceivingResponseEvent(response));

      if (!response.isCancelled) {
        final exchange = _matcher.receiveResponse(response);
        if (exchange != null) {
          response.rtt =
              ((DateTime.now().difference(exchange.timestamp!)).inMilliseconds)
                  .toDouble();
          exchange.endpoint = this;
          _coapStack.receiveResponse(exchange, response);
        } else if (response.type != CoapMessageType.ack) {
          _log!.debug('Rejecting unmatchable response from ${event.address}');
          _reject(response);
        }
      }
    } else if (decoder.isEmpty) {
      final message = decoder.decodeEmptyMessage()!;
      message.source = event.address;

      _eventBus.fire(CoapReceivingEmptyMessageEvent(message));

      if (!message.isCancelled) {
        // CoAP Ping
        if (message.type == CoapMessageType.con ||
            message.type == CoapMessageType.non) {
          _log!.debug('Responding to ping by ${event.address}');
          _reject(message);
        } else {
          final exchange = _matcher.receiveEmptyMessage(message);
          if (exchange != null) {
            exchange.endpoint = this;
            _coapStack.receiveEmptyMessage(exchange, message);
          }
        }
      }
    } else {
      _log!.debug('Silently ignoring non-CoAP message from ${event.address}');
    }
  }

  @override
  Future<void> sendRequest(CoapExchange exchange, CoapRequest request) async {
    _matcher.sendRequest(exchange, request);
    _eventBus.fire(CoapSendingRequestEvent(request));

    if (!request.isCancelled) {
      _channel.send(_serializeRequest(request), request.destination);
    }
  }

  @override
  void sendResponse(CoapExchange exchange, CoapResponse? response) {
    _matcher.sendResponse(exchange, response);
    _eventBus.fire(CoapSendingResponseEvent(response));

    if (!response!.isCancelled) {
      _channel.send(_serializeResponse(response), response.destination);
    }
  }

  @override
  void sendEmptyMessage(CoapExchange exchange, CoapEmptyMessage message) {
    _matcher.sendEmptyMessage(exchange, message);
    _eventBus.fire(CoapSendingEmptyMessageEvent(message));

    if (!message.isCancelled) {
      _channel.send(_serializeEmpty(message), message.destination);
    }
  }

  void _reject(CoapMessage message) {
    final rst = CoapEmptyMessage.newRST(message);
    _eventBus.fire(CoapSendingEmptyMessageEvent(rst));

    if (!rst.isCancelled) {
      _channel.send(_serializeEmpty(rst), rst.destination);
    }
  }

  typed.Uint8Buffer _serializeEmpty(CoapEmptyMessage message) {
    var bytes = message.bytes;
    if (bytes == null) {
      bytes = _config.spec!.newMessageEncoder().encodeMessage(message);
      message.bytes = bytes;
    }
    return bytes!;
  }

  typed.Uint8Buffer _serializeRequest(CoapMessage message) {
    var bytes = message.bytes;
    if (bytes == null) {
      bytes = _config.spec!.newMessageEncoder().encodeMessage(message);
      message.bytes = bytes;
    }
    return bytes!;
  }

  typed.Uint8Buffer _serializeResponse(CoapMessage message) {
    var bytes = message.bytes;
    if (bytes == null) {
      bytes = _config.spec!.newMessageEncoder().encodeMessage(message);
      message.bytes = bytes;
    }
    return bytes!;
  }
}
