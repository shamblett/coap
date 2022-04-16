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
  CoapEndPoint(this._socket, this._config, {required String namespace})
      : _eventBus = CoapEventBus(namespace: namespace),
        _matcher = CoapMatcher(_config, namespace: namespace),
        _coapStack = CoapStack(_config),
        _currentId = _config.useRandomIDStart ? Random().nextInt(1 << 16) : 0 {
    subscr = _eventBus.on<CoapDataReceivedEvent>().listen(_receiveData);
  }

  final CoapEventBus _eventBus;

  @override
  String get namespace => _eventBus.namespace;

  final DefaultCoapConfig _config;

  @override
  DefaultCoapConfig get config => _config;

  int _currentId;

  @override
  int get nextMessageId {
    if (++_currentId >= (1 << 16)) {
      _currentId = 1;
    }
    return _currentId;
  }

  @override
  CoapInternetAddress? get destination => _socket.address;

  final CoapStack _coapStack;
  late final StreamSubscription subscr;

  final CoapIMatcher _matcher;

  final CoapINetwork _socket;

  @override
  CoapInternetAddress? get localEndpoint => _socket.address;

  /// Executor
  CoapIExecutor executor = CoapExecutor();

  @override
  CoapIOutbox get outbox => this;

  @override
  Future<void> start() async {
    try {
      _matcher.start();
    } on Exception {
      stop();
      rethrow;
    }
  }

  @override
  void stop() {
    _matcher.stop();
    _eventBus.destroy();
    _socket.close();
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
      } on Exception {
        if (!decoder.isReply) {
          // Manually build RST from raw information
          final rst = CoapEmptyMessage(CoapMessageType.rst);
          rst.destination = event.address;
          rst.id = decoder.id;
          _eventBus.fire(CoapSendingEmptyMessageEvent(rst));
          _socket.send(_serializeEmpty(rst), rst.destination);
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
          _reject(message);
        } else {
          final exchange = _matcher.receiveEmptyMessage(message);
          if (exchange != null) {
            exchange.endpoint = this;
            _coapStack.receiveEmptyMessage(exchange, message);
          }
        }
      }
    }
  }

  @override
  Future<void> sendRequest(CoapExchange exchange, CoapRequest request) async {
    _matcher.sendRequest(exchange, request);
    _eventBus.fire(CoapSendingRequestEvent(request));

    if (!request.isCancelled) {
      _socket.send(_serializeRequest(request), request.destination);
    }
  }

  @override
  void sendResponse(CoapExchange exchange, CoapResponse? response) {
    _matcher.sendResponse(exchange, response);
    _eventBus.fire(CoapSendingResponseEvent(response));

    if (!response!.isCancelled) {
      _socket.send(_serializeResponse(response), response.destination);
    }
  }

  @override
  void sendEmptyMessage(CoapExchange exchange, CoapEmptyMessage message) {
    _matcher.sendEmptyMessage(exchange, message);
    _eventBus.fire(CoapSendingEmptyMessageEvent(message));

    if (!message.isCancelled) {
      _socket.send(_serializeEmpty(message), message.destination);
    }
  }

  void _reject(CoapMessage message) {
    final rst = CoapEmptyMessage.newRST(message);
    _eventBus.fire(CoapSendingEmptyMessageEvent(rst));

    if (!rst.isCancelled) {
      _socket.send(_serializeEmpty(rst), rst.destination);
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
