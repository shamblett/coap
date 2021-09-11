/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 11/09/2019
 * Copyright :  S.Hamblett
 */

part of coap;

/// Acknowledged event
class CoapAcknowledgedEvent {}

/// Rejected event
class CoapRejectedEvent {}

/// Timed out event
class CoapTimedOutEvent {}

/// Cancelled event
class CoapCancelledEvent {}

/// Response event
class CoapRespondEvent {
  /// Construction
  CoapRespondEvent(this.resp);

  /// Response
  CoapResponse? resp;
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
  CoapSendingRequestEvent(this.request);

  /// The request
  CoapRequest request;
}

/// Occurs when a response is about to be sent.
class CoapSendingResponseEvent {
  /// Construction
  CoapSendingResponseEvent(this.response);

  /// The response
  CoapResponse? response;
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
  CoapReceivingRequestEvent(this.request);

  /// The request
  CoapRequest? request;
}

/// Occurs when a response has been received.
class CoapReceivingResponseEvent {
  /// Construction
  CoapReceivingResponseEvent(this.response);

  /// The response
  CoapResponse response;
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
  static CoapEventBus? _instance;

  /// Construction
  factory CoapEventBus() => _singleton!;

  CoapEventBus._internal(this._destroyed) {
    _eventBus = events.EventBus();
    _instance = this;
  }

  /// Last event fired, useful for testing
  dynamic lastEvent;

  final CoapILogger? _log = CoapLogManager().logger;
  late events.EventBus _eventBus;
  bool _destroyed;

  /// Fire
  void fire(dynamic event) {
    if (!_destroyed) {
      lastEvent = event;
      _eventBus.fire(event);
    } else {
      _log!.warn('Event Bus - attempting to raise event on '
          'destroyed event bus : $event');
    }
  }

  /// On
  Stream<T> on<T>() => _eventBus.on();

  /// Destroy
  void destroy() {
    _eventBus.destroy();
    _destroyed = true;
    _instance = null;
  }

  static final CoapEventBus? _singleton =
      _instance == null ? CoapEventBus._internal(false) : _instance;
}
