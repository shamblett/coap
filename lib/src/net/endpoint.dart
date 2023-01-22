/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
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
import '../network/coap_inetwork.dart';
import '../network/coap_network_openssl.dart';
import '../network/coap_network_udp.dart';
import '../network/credentials/psk_credentials.dart';
import '../stack/layer_stack.dart';
import 'exchange.dart';
import 'matcher.dart';

/// EndPoint encapsulates the stack that executes the CoAP protocol.
class Endpoint {
  /// Instantiates a new endpoint with the
  /// specified channel and configuration.
  Endpoint(
    this._config,
    final PskCredentialsCallback? pskCredentialsCallback, {
    required final String namespace,
  })  : _eventBus = CoapEventBus(namespace: namespace),
        _matcher = CoapMatcher(_config, namespace: namespace),
        _coapStack = LayerStack(_config),
        _currentId = _config.useRandomIDStart ? Random().nextInt(1 << 16) : 0,
        _udpNetwork = CoapNetworkUDP(namespace: namespace),
        _dtlsNetwork = CoapNetworkUDPOpenSSL(
          ciphers: _config.dtlsCiphers,
          verify: _config.dtlsVerify,
          withTrustedRoots: _config.dtlsWithTrustedRoots,
          rootCertificates: _config.rootCertificates,
          pskCredentialsCallback: pskCredentialsCallback,
          namespace: namespace,
        ) {
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

  final CoapNetworkUDP _udpNetwork;

  final CoapNetworkUDPOpenSSL _dtlsNetwork;

  final LayerStack _coapStack;
  late final StreamSubscription<CoapMessageReceivedEvent> subscr;

  final CoapMatcher _matcher;

  Future<void> start() async {
    try {
      subscr.resume();
      _matcher.start();
    } on Exception catch (_) {
      await stop();
      rethrow;
    }
  }

  Future<void> stop() async {
    _matcher.stop();
    _udpNetwork.close();
    await _dtlsNetwork.close();
    await subscr.cancel();
    // Close event bus last to catch as many events as possible
    _eventBus.destroy();
  }

  void clear() {
    _matcher.clear();
  }

  Future<void> sendEpRequest(final CoapRequest request) async {
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

  void _receiveMessage(final CoapMessageReceivedEvent event) {
    final message = event.coapMessage;
    final uri = event.peerUri;

    if (message == null) {
      return;
    }

    if (message.needsRejection) {
      _reject(message, uri);
      return;
    }

    message.source = event.address;

    if (message is CoapRequest) {
      final request = message;
      _eventBus.fire(CoapReceivingRequestEvent(request));

      if (!request.isCancelled) {
        final exchange = _matcher.receiveRequest(request);
        _coapStack.receiveRequest(exchange, request);
      }
    } else if (message is CoapResponse) {
      final response = message;
      _eventBus.fire(CoapReceivingResponseEvent(response));

      if (response.hasUnknownCriticalOption) {
        _reject(response, uri);
      } else if (!response.isCancelled) {
        final exchange = _matcher.receiveResponse(response);
        if (exchange != null) {
          response.rtt = DateTime.now().difference(exchange.timestamp!);
          _coapStack.receiveResponse(exchange, response);
        } else if (response.type != CoapMessageType.ack) {
          _reject(response, uri);
        }
      }
    } else if (message is CoapEmptyMessage) {
      _eventBus.fire(CoapReceivingEmptyMessageEvent(message));

      if (!message.isCancelled) {
        // CoAP Ping
        if (message.type == CoapMessageType.con ||
            message.type == CoapMessageType.non) {
          _reject(message, uri);
        } else {
          final exchange = _matcher.receiveEmptyMessage(message);
          if (exchange != null) {
            _coapStack.receiveEmptyMessage(exchange, message);
          }
        }
      }
    }
  }

  Future<void> sendRequest(
    final CoapExchange exchange,
    final CoapRequest request,
  ) async {
    _matcher.sendRequest(exchange, request);
    _eventBus.fire(CoapSendingRequestEvent(request));

    await _sendMessage(request, request.uri);
  }

  Future<void> sendResponse(
    final CoapExchange exchange,
    final CoapResponse response,
  ) async {
    _matcher.sendResponse(exchange, response);
    _eventBus.fire(CoapSendingResponseEvent(response));

    final uri = exchange.request.uri;
    await _sendMessage(response, uri);
  }

  Future<void> sendEmptyMessage(
    final CoapExchange exchange,
    final CoapEmptyMessage message,
  ) async {
    _matcher.sendEmptyMessage(exchange, message);
    _eventBus.fire(CoapSendingEmptyMessageEvent(message));

    final uri = exchange.request.uri;
    await _sendMessage(message, uri);
  }

  void _reject(final CoapMessage message, final Uri uri) {
    final rst = CoapEmptyMessage.newRST(message);
    _eventBus.fire(CoapSendingEmptyMessageEvent(rst));

    _sendMessage(rst, uri);
  }

  Future<void> _sendMessage(
    final CoapMessage message,
    final Uri uri,
  ) async {
    if (!message.isCancelled) {
      final CoapINetwork network;
      switch (uri.scheme) {
        case 'coap':
          network = _udpNetwork;
          break;
        case 'coaps':
          network = _dtlsNetwork;
          break;
        default:
          throw Exception();
      }
      return network.sendMessage(message, uri);
    }
  }
}
