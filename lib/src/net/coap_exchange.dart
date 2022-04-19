/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Represents the complete state of an exchange of one request
/// and one or more responses. The lifecycle of an exchange ends
/// when either the last response has arrived and is acknowledged,
/// when a request or response has been rejected from the remote endpoint,
/// when the request has been canceled, or when a request or response timed out,
/// i.e., has reached the retransmission limit without being acknowledged.
class CoapExchange {
  /// Construction
  CoapExchange(this.request, this._origin, {required String namespace}) {
    _eventBus = CoapEventBus(namespace: namespace);
    _timestamp = DateTime.now();
  }

  late final CoapEventBus _eventBus;

  final Map<Object, Object> _attributes = <Object, Object>{};
  final CoapOrigin _origin;

  /// The origin
  CoapOrigin get origin => _origin;

  /// The request
  CoapRequest? request;

  /// The request
  CoapRequest? originalMulticastRequest;

  /// The current request
  CoapRequest? currentRequest;

  /// The response
  CoapResponse? response;

  /// The current response
  CoapResponse? currentResponse;

  /// The endpoint which has created and processed this exchange.
  CoapIEndPoint? endpoint;

  DateTime? _timestamp;

  /// Time
  DateTime? get timestamp => _timestamp;

  /// the status of the blockwise transfer of the response,
  /// or null in case of a normal transfer,
  CoapBlockwiseStatus? responseBlockStatus;

  /// The status of the blockwise transfer of the request,
  /// or null in case of a normal transfer
  CoapBlockwiseStatus? requestBlockStatus;

  /// The block option of the last block of a blockwise sent request.
  /// When the server sends the response, this block option has
  /// to be acknowledged.
  CoapBlockOption? block1ToAck;

  /// Observe relation
  CoapObserveRelation? relation;

  late bool _timedOut;

  /// Timed out
  bool get timedOut => _timedOut;

  set timedOut(bool value) {
    _timedOut = value;
    if (value) {
      complete = true;
    }
  }

  late bool _complete;

  /// Complete
  bool get complete => _complete;

  set complete(bool value) {
    _complete = value;
    if (value) {
      _eventBus.fire(CoapCompletedEvent(this));
    }
  }

  CoapIOutbox? _outbox;

  /// Outbox
  CoapIOutbox? get outbox => _outbox ?? endpoint?.outbox;

  set outbox(CoapIOutbox? value) => _outbox = value;

  /// Reject this exchange and therefore the request.
  /// Sends an RST back to the client.
  void sendReject() {
    assert(_origin == CoapOrigin.remote, 'Origin must be remote');
    request!.isRejected = true;
    final rst = CoapEmptyMessage.newRST(request!);
    endpoint!.sendEpEmptyMessage(this, rst);
  }

  /// Accept this exchange and therefore the request. Only if the request's
  /// type was a CON and the request has not been acknowledged
  /// yet, it sends an ACK to the client.
  void sendAccept() {
    assert(_origin == CoapOrigin.remote, 'Origin must be remote');
    if (request!.type == CoapMessageType.con && !request!.isAcknowledged) {
      request!.isAcknowledged = true;
      final ack = CoapEmptyMessage.newACK(request!);
      endpoint!.sendEpEmptyMessage(this, ack);
    }
  }

  /// Sends the specified response over the same endpoint
  /// as the request has arrived.
  void sendResponse(CoapResponse resp) {
    resp.destination = request!.source;
    response = resp;
    endpoint!.sendEpResponse(this, resp);
  }

  /// Fire the reregistering event
  void fireReregistering(CoapRequest req) {
    _eventBus.fire(CoapReregisteringEvent(req));
  }

  /// Fire the responding event
  void fireResponding(CoapResponse resp) {
    _eventBus.fire(CoapRespondingEvent(resp));
  }

  // Fire the respond event
  void fireRespond(CoapResponse resp) {
    // block1 requests only have token set on their blocks
    request!.token ??= currentRequest!.token;
    _eventBus.fire(CoapRespondEvent(resp));
  }

  /// Attributes
  T? get<T>(Object key) => _attributes[key] as T?;

  /// Get or add an attribute
  T? getOrAdd<T>(Object key, Object value) {
    if (!_attributes.containsKey(key)) {
      _attributes[key] = value;
    }
    return _attributes[key] as T?;
  }

  /// Set an attribute
  T? set<T>(Object key, Object value) {
    Object? oldValue;
    if (_attributes.containsKey(key)) {
      oldValue = _attributes[key];
    }
    _attributes[key] = value;
    return oldValue as T?;
  }

  /// Remove
  Object? remove(Object key) => _attributes.remove(key);
}
