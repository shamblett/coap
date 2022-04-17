/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 11/09/2019
 * Copyright :  S.Hamblett
 */

part of coap;

/// Acknowledged event
class CoapAcknowledgedEvent {
  CoapAcknowledgedEvent(this.msg);

  CoapMessage msg;
}

/// Rejected event
class CoapRejectedEvent {
  CoapRejectedEvent(this.msg);

  CoapMessage msg;
}

/// Retransmitted event
class CoapRetransmitEvent {
  CoapRetransmitEvent(this.msg);

  CoapMessage msg;
}

/// Timed out event
class CoapTimedOutEvent {
  CoapTimedOutEvent(this.msg);

  CoapMessage msg;
}

/// Cancelled event
class CoapCancelledEvent {
  CoapCancelledEvent(this.msg);

  CoapMessage msg;
}

/// Response event
class CoapRespondEvent {
  /// Construction
  CoapRespondEvent(this.resp);

  /// Response
  CoapResponse resp;
}

/// Responding event
class CoapRespondingEvent {
  /// Construction
  CoapRespondingEvent(this.resp);

  /// Response
  CoapResponse resp;
}

/// Registering event
class CoapReregisteringEvent {
  /// Construction
  CoapReregisteringEvent(this.resp);

  /// Response
  CoapRequest resp;
}

/// Occurs when a request is about to be sent.
class CoapSendingRequestEvent {
  /// Construction
  CoapSendingRequestEvent(this.req);

  /// The request
  CoapRequest req;
}

/// Occurs when a response is about to be sent.
class CoapSendingResponseEvent {
  /// Construction
  CoapSendingResponseEvent(this.resp);

  /// The response
  CoapResponse resp;
}

/// Occurs when a an empty message is about to be sent.
class CoapSendingEmptyMessageEvent {
  /// Construction
  CoapSendingEmptyMessageEvent(this.empty);

  /// The empty message
  CoapEmptyMessage empty;
}

/// Occurs when a request has been received.
class CoapReceivingRequestEvent {
  /// Construction
  CoapReceivingRequestEvent(this.req);

  /// The request
  CoapRequest req;
}

/// Occurs when a response has been received.
class CoapReceivingResponseEvent {
  /// Construction
  CoapReceivingResponseEvent(this.resp);

  /// The response
  CoapResponse resp;
}

/// Occurs when an empty message has been received.
class CoapReceivingEmptyMessageEvent {
  /// Construction
  CoapReceivingEmptyMessageEvent(this.empty);

  /// The empty message
  CoapEmptyMessage empty;
}

/// Completed event
class CoapCompletedEvent {
  /// Construction
  CoapCompletedEvent(this.exchange);

  /// The exchange
  CoapExchange exchange;
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
  typed.Uint8Buffer data;

  /// The address
  CoapInternetAddress? address;
}

/// Event bus class
class CoapEventBus {
  /// Construction
  factory CoapEventBus({required String namespace}) =>
      _singletons[namespace] ??= CoapEventBus._internal(namespace);

  final String namespace;

  CoapEventBus._internal(this.namespace) : _eventBus = events.EventBus();

  /// Last event fired, useful for testing
  dynamic lastEvent;

  late final events.EventBus _eventBus;
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
