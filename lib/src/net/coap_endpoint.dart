/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:math';

import 'package:typed_data/typed_data.dart';

import '../coap_config.dart';
import '../coap_empty_message.dart';
import '../coap_message.dart';
import '../coap_message_type.dart';
import '../coap_request.dart';
import '../coap_response.dart';
import '../event/coap_event_bus.dart';
import '../network/coap_inetwork.dart';
import '../stack/coap_stack.dart';
import '../tasks/coap_executor.dart';
import '../tasks/coap_iexecutor.dart';
import 'coap_exchange.dart';
import 'coap_iendpoint.dart';
import 'coap_imatcher.dart';
import 'coap_internet_address.dart';
import 'coap_ioutbox.dart';
import 'coap_matcher.dart';

/// EndPoint encapsulates the stack that executes the CoAP protocol.
class CoapEndPoint implements CoapIEndPoint, CoapIOutbox {
  /// Instantiates a new endpoint with the
  /// specified channel and configuration.
  CoapEndPoint(this._socket, this._config, {required final String namespace})
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
  late final StreamSubscription<CoapDataReceivedEvent> subscr;

  final CoapIMatcher _matcher;

  final CoapINetwork _socket;

  /// Executor
  CoapIExecutor executor = CoapExecutor();

  @override
  CoapIOutbox get outbox => this;

  @override
  Future<void> start() async {
    try {
      subscr.resume();
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
    subscr.cancel();
  }

  @override
  void clear() {
    _matcher.clear();
  }

  @override
  void sendEpRequest(final CoapRequest request) {
    executor.start(() => _coapStack.sendRequest(request));
  }

  @override
  void sendEpResponse(
    final CoapExchange exchange,
    final CoapResponse response,
  ) {
    executor.start(() => _coapStack.sendResponse(exchange, response));
  }

  @override
  void sendEpEmptyMessage(
    final CoapExchange exchange,
    final CoapEmptyMessage message,
  ) {
    executor.start(() => _coapStack.sendEmptyMessage(exchange, message));
  }

  void _receiveData(final CoapDataReceivedEvent event) {
    // clone the data, in case other objects want to do stuff with it, too
    final data = Uint8Buffer()..addAll(event.data);
    // Return if we have no data, should not happen but be defensive
    final decoder = config.spec.newMessageDecoder(data);
    if (decoder.isRequest) {
      CoapRequest? request;
      try {
        request = decoder.decodeRequest();
      } on Exception {
        if (!decoder.isReply) {
          // Manually build RST from raw information
          final rst = CoapEmptyMessage(CoapMessageType.rst)
            ..destination = event.address
            ..id = decoder.id;
          _eventBus.fire(CoapSendingEmptyMessageEvent(rst));
          _socket.send(_serializeEmpty(rst), rst.destination);
        }
        return;
      }

      request!.source = event.address;
      _eventBus.fire(CoapReceivingRequestEvent(request));

      if (!request.isCancelled) {
        final exchange = _matcher.receiveRequest(request)..endpoint = this;
        _coapStack.receiveRequest(exchange, request);
      }
    } else if (decoder.isResponse) {
      final response = decoder.decodeResponse()!..source = event.address;
      _eventBus.fire(CoapReceivingResponseEvent(response));

      if (response.hasUnknownCriticalOption) {
        _reject(response);
      } else if (!response.isCancelled) {
        final exchange = _matcher.receiveResponse(response);
        if (exchange != null) {
          response.rtt = DateTime.now().difference(exchange.timestamp!);
          exchange.endpoint = this;
          _coapStack.receiveResponse(exchange, response);
        } else if (response.type != CoapMessageType.ack) {
          _reject(response);
        }
      }
    } else if (decoder.isEmpty) {
      final message = decoder.decodeEmptyMessage()!..source = event.address;

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
  Future<void> sendRequest(
    final CoapExchange exchange,
    final CoapRequest request,
  ) async {
    _matcher.sendRequest(exchange, request);
    _eventBus.fire(CoapSendingRequestEvent(request));

    if (!request.isCancelled) {
      await _socket.send(_serializeRequest(request), request.destination);
    }
  }

  @override
  void sendResponse(final CoapExchange exchange, final CoapResponse response) {
    _matcher.sendResponse(exchange, response);
    _eventBus.fire(CoapSendingResponseEvent(response));

    if (!response.isCancelled) {
      _socket.send(_serializeResponse(response), response.destination);
    }
  }

  @override
  void sendEmptyMessage(
    final CoapExchange exchange,
    final CoapEmptyMessage message,
  ) {
    _matcher.sendEmptyMessage(exchange, message);
    _eventBus.fire(CoapSendingEmptyMessageEvent(message));

    if (!message.isCancelled) {
      _socket.send(_serializeEmpty(message), message.destination);
    }
  }

  void _reject(final CoapMessage message) {
    final rst = CoapEmptyMessage.newRST(message);
    _eventBus.fire(CoapSendingEmptyMessageEvent(rst));

    if (!rst.isCancelled) {
      _socket.send(_serializeEmpty(rst), rst.destination);
    }
  }

  Uint8Buffer _serializeEmpty(final CoapEmptyMessage message) {
    var bytes = message.bytes;
    if (bytes == null) {
      bytes = _config.spec.newMessageEncoder().encodeMessage(message);
      message.bytes = bytes;
    }
    if (bytes != null) {
      return bytes;
    } else {
      return Uint8Buffer();
    }
  }

  Uint8Buffer _serializeRequest(final CoapMessage message) {
    var bytes = message.bytes;
    if (bytes == null) {
      bytes = _config.spec.newMessageEncoder().encodeMessage(message);
      message.bytes = bytes;
    }
    return bytes!;
  }

  Uint8Buffer _serializeResponse(final CoapMessage message) {
    var bytes = message.bytes;
    if (bytes == null) {
      bytes = _config.spec.newMessageEncoder().encodeMessage(message);
      message.bytes = bytes;
    }
    return bytes!;
  }
}
