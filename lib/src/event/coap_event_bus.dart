/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 11/09/2019
 * Copyright :  S.Hamblett
 */

import 'package:event_bus/event_bus.dart';
import 'package:typed_data/typed_data.dart';

import '../coap_empty_message.dart';
import '../coap_message.dart';
import '../coap_request.dart';
import '../coap_response.dart';
import '../net/coap_exchange.dart';
import '../net/coap_internet_address.dart';

abstract class CoapMessageEvent {
  CoapMessageEvent(this.msg);

  /// Event message
  CoapMessage msg;

  @override
  String toString() => '$runtimeType: $msg';
}

abstract class CoapRequestEvent {
  CoapRequestEvent(this.req);

  /// Event request
  CoapRequest req;

  @override
  String toString() => '$runtimeType: $req';
}

abstract class CoapResponseEvent {
  CoapResponseEvent(this.resp);

  /// Event response
  CoapResponse resp;

  @override
  String toString() => '$runtimeType: $resp';
}

abstract class CoapExchangeEvent {
  CoapExchangeEvent(this.exchange);

  /// Event exchange
  CoapExchange exchange;

  @override
  String toString() =>
      '$runtimeType:\nExchange for request ${exchange.request?.id} '
      '(token \'${exchange.request?.tokenString}\')';
}

/// Acknowledged event
class CoapAcknowledgedEvent extends CoapMessageEvent {
  CoapAcknowledgedEvent(CoapMessage msg) : super(msg);
}

/// Rejected event
class CoapRejectedEvent extends CoapMessageEvent {
  CoapRejectedEvent(CoapMessage msg) : super(msg);
}

/// Retransmitted event
class CoapRetransmitEvent extends CoapMessageEvent {
  CoapRetransmitEvent(CoapMessage msg) : super(msg);
}

/// Timed out event
class CoapTimedOutEvent extends CoapMessageEvent {
  CoapTimedOutEvent(CoapMessage msg) : super(msg);
}

/// Cancelled event
class CoapCancelledEvent extends CoapMessageEvent {
  CoapCancelledEvent(CoapMessage msg) : super(msg);
}

/// Response event
class CoapRespondEvent extends CoapResponseEvent {
  CoapRespondEvent(CoapResponse resp) : super(resp);
}

/// Responding event
class CoapRespondingEvent extends CoapResponseEvent {
  CoapRespondingEvent(CoapResponse resp) : super(resp);
}

/// Registering event
class CoapReregisteringEvent extends CoapRequestEvent {
  CoapReregisteringEvent(CoapRequest req) : super(req);
}

/// Occurs when a request is about to be sent.
class CoapSendingRequestEvent extends CoapRequestEvent {
  CoapSendingRequestEvent(CoapRequest req) : super(req);
}

/// Occurs when a response is about to be sent.
class CoapSendingResponseEvent extends CoapResponseEvent {
  CoapSendingResponseEvent(CoapResponse resp) : super(resp);
}

/// Occurs when a an empty message is about to be sent.
class CoapSendingEmptyMessageEvent extends CoapMessageEvent {
  CoapSendingEmptyMessageEvent(CoapMessage empty) : super(empty);
}

/// Occurs when a request has been received.
class CoapReceivingRequestEvent extends CoapRequestEvent {
  CoapReceivingRequestEvent(CoapRequest req) : super(req);
}

/// Occurs when a response has been received.
class CoapReceivingResponseEvent extends CoapResponseEvent {
  CoapReceivingResponseEvent(CoapResponse resp) : super(resp);
}

/// Occurs when an empty message has been received.
class CoapReceivingEmptyMessageEvent extends CoapMessageEvent {
  CoapReceivingEmptyMessageEvent(CoapEmptyMessage empty) : super(empty);
}

/// Completed event
class CoapCompletedEvent extends CoapExchangeEvent {
  CoapCompletedEvent(CoapExchange exchange) : super(exchange);
}

/// The origin of an exchange.
enum CoapOrigin {
  /// Local
  local,

  /// Remote
  remote
}

/// Data received Event
class CoapDataReceivedEvent {
  /// Construction
  CoapDataReceivedEvent(this.data, this.address);

  /// The data
  Uint8Buffer data;

  /// The address
  CoapInternetAddress address;

  @override
  String toString() => '$runtimeType:\n$data from ${address.address}';
}

/// Event bus class
class CoapEventBus {
  /// Construction
  factory CoapEventBus({required String namespace}) =>
      _singletons[namespace] ??= CoapEventBus._internal(namespace);

  final String namespace;

  CoapEventBus._internal(this.namespace) : _eventBus = EventBus();

  /// Last event fired, useful for testing
  dynamic lastEvent;

  late final EventBus _eventBus;
  bool _destroyed = false;

  /// Fire
  void fire(dynamic event) {
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

  static final _singletons = <String, CoapEventBus>{};
}
