/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 11/09/2019
 * Copyright :  S.Hamblett
 */

import 'dart:io';

import 'package:event_bus/event_bus.dart';

import '../coap_empty_message.dart';
import '../coap_message.dart';
import '../coap_request.dart';
import '../coap_response.dart';
import '../net/exchange.dart';

/// Interface for events that yield a [CoapResponse] or an [Exception].
abstract class CoapCompletionEvent {}

abstract class CoapMessageEvent {
  /// Event message
  CoapMessage msg;

  CoapMessageEvent(this.msg);

  @override
  String toString() => 'CoapMessageEvent: $msg';
}

abstract class CoapRequestEvent {
  /// Event request
  CoapRequest req;

  CoapRequestEvent(this.req);

  @override
  String toString() => 'CoapRequestEvent: $req';
}

abstract class CoapResponseEvent {
  /// Event response
  CoapResponse resp;

  CoapResponseEvent(this.resp);

  @override
  String toString() => 'CoapResponseEvent: $resp';
}

abstract class CoapExchangeEvent {
  /// Event exchange
  CoapExchange exchange;

  CoapExchangeEvent(this.exchange);

  @override
  String toString() =>
      'CoapExchangeEvent:\nExchange for request ${exchange.request.id} '
      "(token '${exchange.request.tokenString}')";
}

/// Acknowledged event
class CoapAcknowledgedEvent extends CoapMessageEvent {
  CoapAcknowledgedEvent(super.msg);
}

/// Rejected event
class CoapRejectedEvent extends CoapMessageEvent {
  CoapRejectedEvent(super.msg);
}

/// Retransmitted event
class CoapRetransmitEvent extends CoapMessageEvent {
  CoapRetransmitEvent(super.msg);
}

/// Timed out event
class CoapTimedOutEvent extends CoapMessageEvent
    implements CoapCompletionEvent {
  CoapTimedOutEvent(super.msg);
}

/// Cancelled event
class CoapCancelledEvent extends CoapMessageEvent {
  CoapCancelledEvent(super.msg);
}

/// Response event
class CoapRespondEvent extends CoapResponseEvent
    implements CoapCompletionEvent {
  CoapRespondEvent(super.resp);
}

/// Responding event
class CoapRespondingEvent extends CoapResponseEvent {
  CoapRespondingEvent(super.resp);
}

/// Registering event
class CoapReregisteringEvent extends CoapRequestEvent {
  CoapReregisteringEvent(super.req);
}

/// Occurs when a request is about to be sent.
class CoapSendingRequestEvent extends CoapRequestEvent {
  CoapSendingRequestEvent(super.req);
}

/// Occurs when a response is about to be sent.
class CoapSendingResponseEvent extends CoapResponseEvent {
  CoapSendingResponseEvent(super.resp);
}

/// Occurs when a an empty message is about to be sent.
class CoapSendingEmptyMessageEvent extends CoapMessageEvent {
  CoapSendingEmptyMessageEvent(super.empty);
}

/// Occurs when a request has been received.
class CoapReceivingRequestEvent extends CoapRequestEvent {
  CoapReceivingRequestEvent(super.req);
}

/// Occurs when a response has been received.
class CoapReceivingResponseEvent extends CoapResponseEvent {
  CoapReceivingResponseEvent(super.resp);
}

/// Occurs when an empty message has been received.
class CoapReceivingEmptyMessageEvent extends CoapMessageEvent {
  CoapReceivingEmptyMessageEvent(CoapEmptyMessage super.empty);
}

/// Completed event
class CoapCompletedEvent extends CoapExchangeEvent {
  CoapCompletedEvent(super.exchange);
}

/// The origin of an exchange.
enum CoapOrigin {
  /// Local
  local,

  /// Remote
  remote,
}

/// Data received Event
class CoapMessageReceivedEvent {
  /// The data
  final CoapMessage? coapMessage;

  /// The address
  InternetAddress address;

  /// Construction
  CoapMessageReceivedEvent(this.coapMessage, this.address);

  @override
  String toString() =>
      'CoapMessageReceivedEvent:\n$coapMessage from ${address.address}';
}

class CoapSocketInitEvent {
  /// Construction
  CoapSocketInitEvent();

  @override
  String toString() => 'CoapSocketInitEvent:\nSocket attempting to initialize';
}

class CoapSocketErrorEvent {
  /// The socket error
  Object error;

  /// The stack trace of the socket error
  StackTrace stackTrace;

  /// Construction
  CoapSocketErrorEvent(this.error, this.stackTrace);

  @override
  String toString() => 'CoapSocketErrorEvent:\n$error\n$stackTrace';
}

/// Event bus class
class CoapEventBus {
  final String namespace;

  /// Last event fired, useful for testing
  dynamic lastEvent;

  late final EventBus _eventBus;

  bool _destroyed = false;

  static final _singletons = <String, CoapEventBus>{};

  /// Construction
  factory CoapEventBus({required final String namespace}) =>
      _singletons[namespace] ??= CoapEventBus._internal(namespace);

  CoapEventBus._internal(this.namespace) : _eventBus = EventBus();

  /// Fire
  void fire(final Object event) {
    if (!_destroyed) {
      lastEvent = event;
      _eventBus.fire(event);
    }
  }

  /// On
  Stream<T> on<T>() => _eventBus.on();

  /// Destroy
  void destroy() {
    _eventBus.destroy();
    _destroyed = true;
  }
}
