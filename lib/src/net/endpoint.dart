/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:io';
import 'dart:math';

import '../coap_config.dart';
import '../coap_empty_message.dart';
import '../coap_message.dart';
import '../coap_message_type.dart';
import '../coap_request.dart';
import '../coap_response.dart';
import '../event/coap_event_bus.dart';
import '../network/coap_inetwork.dart';
import '../stack/layer_stack.dart';
import 'exchange.dart';
import 'matcher.dart';
import 'outbox.dart';

/// EndPoint encapsulates the stack that executes the CoAP protocol.
class Endpoint implements Outbox {
  /// Instantiates a new endpoint with the
  /// specified channel and configuration.
  Endpoint(this._socket, this._config, {required final String namespace})
      : _eventBus = CoapEventBus(namespace: namespace),
        _matcher = CoapMatcher(_config, namespace: namespace),
        _coapStack = LayerStack(_config),
        _currentId = _config.useRandomIDStart ? Random().nextInt(1 << 16) : 0 {
    subscr = _eventBus.on<CoapMessageReceivedEvent>().listen(_receiveMessage);
  }

  final CoapEventBus _eventBus;

  String get namespace => _eventBus.namespace;

  final DefaultCoapConfig _config;

  DefaultCoapConfig get config => _config;

  int _currentId;

  int get nextMessageId {
    if (++_currentId >= (1 << 16)) {
      _currentId = 1;
    }
    return _currentId;
  }

  InternetAddress? get destination => _socket.address;

  final LayerStack _coapStack;
  late final StreamSubscription<CoapMessageReceivedEvent> subscr;

  final CoapMatcher _matcher;

  final CoapINetwork _socket;

  Outbox get outbox => this;

  void start() {
    try {
      subscr.resume();
      _matcher.start();
    } on Exception catch (_) {
      stop();
      rethrow;
    }
  }

  void stop() {
    _matcher.stop();
    _socket.close();
    subscr.cancel();
    // Close event bus last to catch as many events as possible
    _eventBus.destroy();
  }

  void clear() {
    _matcher.clear();
  }

  void sendEpRequest(final CoapRequest request) {
    _coapStack.sendRequest(request);
  }

  void sendEpResponse(
    final CoapExchange exchange,
    final CoapResponse response,
  ) {
    _coapStack.sendResponse(exchange, response);
  }

  void sendEpEmptyMessage(
    final CoapExchange exchange,
    final CoapEmptyMessage message,
  ) {
    _coapStack.sendEmptyMessage(exchange, message);
  }

  // TODO(JKRhb): Maybe this can be refactored to a needsRejection getter on the
  //              CoapMessage class
  static bool _checkNeedForRejection(final CoapMessage message) =>
      (message.type == CoapMessageType.non &&
          message.hasUnknownCriticalOption) ||
      message.hasFormatError ||
      (message is CoapResponse && message.hasUnknownCriticalOption);

  void _receiveMessage(final CoapMessageReceivedEvent event) {
    final message = event.coapMessage;

    if (message == null) {
      return;
    }

    if (_checkNeedForRejection(message)) {
      _reject(message);
      return;
    }

    message.source = event.address;

    if (message is CoapRequest) {
      // TODO(JKRhb): Does this still need to be taken into account somehow?

      // CoapRequest? request;
      // try {
      //   request = decoder.decodeRequest();
      // } on Exception catch (_) {
      //   if (!decoder.isReply) {
      //     // Manually build RST from raw information
      //     final rst = CoapEmptyMessage(CoapMessageType.rst)
      //       ..destination = event.address
      //       ..id = decoder.id;
      //     _eventBus.fire(CoapSendingEmptyMessageEvent(rst));
      //     _socket.send(rst, rst.destination);
      //   }
      //   return;
      // }

      final request = message;
      _eventBus.fire(CoapReceivingRequestEvent(request));

      if (!request.isCancelled) {
        final exchange = _matcher.receiveRequest(request)..endpoint = this;
        _coapStack.receiveRequest(exchange, request);
      }
    } else if (message is CoapResponse) {
      final response = message;
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
    } else if (message is CoapEmptyMessage) {
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
  void sendRequest(
    final CoapExchange exchange,
    final CoapRequest request,
  ) {
    _matcher.sendRequest(exchange, request);
    _eventBus.fire(CoapSendingRequestEvent(request));

    _sendMessage(request);
  }

  @override
  void sendResponse(final CoapExchange exchange, final CoapResponse response) {
    _matcher.sendResponse(exchange, response);
    _eventBus.fire(CoapSendingResponseEvent(response));

    _sendMessage(response);
  }

  @override
  void sendEmptyMessage(
    final CoapExchange exchange,
    final CoapEmptyMessage message,
  ) {
    _matcher.sendEmptyMessage(exchange, message);
    _eventBus.fire(CoapSendingEmptyMessageEvent(message));

    _sendMessage(message);
  }

  void _reject(final CoapMessage message) {
    final rst = CoapEmptyMessage.newRST(message);
    _eventBus.fire(CoapSendingEmptyMessageEvent(rst));

    _sendMessage(rst);
  }

  void _sendMessage(final CoapMessage message) {
    if (!message.isCancelled) {
      _socket.send(message);
    }
  }
}
