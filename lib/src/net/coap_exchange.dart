/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Events
class CoapCompletedEvent {
  CoapCompletedEvent(this.exchange);

  CoapExchange exchange;
}

/// The origin of an exchange.
enum CoapOrigin { local, remote }

/// Represents the complete state of an exchange of one request
/// and one or more responses. The lifecycle of an exchange ends
/// when either the last response has arrived and is acknowledged,
/// when a request or response has been rejected from the remote endpoint,
/// when the request has been canceled, or when a request or response timed out,
/// i.e., has reached the retransmission limit without being acknowledged.
class CoapExchange extends Object with events.EventEmitter {
  CoapExchange(CoapRequest request, CoapOrigin origin) {
    _origin = origin;
    currentRequest = request;
    _timestamp = new DateTime.now();
  }

  Map<Object, Object> _attributes = new Map<Object, Object>();
  CoapOrigin _origin;

  CoapOrigin get origin => _origin;

  CoapRequest request;
  CoapRequest currentRequest;
  CoapResponse response;
  CoapResponse currentResponse;

  /// The endpoint which has created and processed this exchange.
  CoapIEndPoint endpoint;

  DateTime _timestamp;

  DateTime get timestamp => _timestamp;

  /// the status of the blockwise transfer of the response,
  /// or null in case of a normal transfer,
  CoapBlockwiseStatus responseBlockStatus;

  /// The status of the blockwise transfer of the request,
  /// or null in case of a normal transfer
  CoapBlockwiseStatus requestBlockStatus;

  /// The block option of the last block of a blockwise sent request.
  /// When the server sends the response, this block option has to be acknowledged.
  CoapBlockOption block1ToAck;

  CoapObserveRelation relation;

  bool _timedOut;

  bool get timedOut => _timedOut;

  set timedOut(bool value) {
    _timedOut = value;
    if (value) {
      complete = true;
    }
  }

  bool _complete;

  bool get complete => _complete;

  set complete(bool value) {
    _complete = value;
    if (value) {
      emitEvent(new CoapCompletedEvent(this));
    }
  }

  CoapIOutbox _outbox;

  CoapIOutbox get outbox =>
      _outbox ?? (endpoint == null ? null : endpoint.outbox);

  set outbox(CoapIOutbox value) => _outbox = value;

  CoapIMessageDeliverer _deliverer;

  CoapIMessageDeliverer get deliverer =>
      _deliverer ?? (endpoint == null ? null : endpoint.deliverer);

  set deliverer(CoapIMessageDeliverer value) => _deliverer = value;

  /// Reject this exchange and therefore the request.
  /// Sends an RST back to the client.
  void sendReject() {
    assert(_origin == CoapOrigin.remote);
    request.isRejected = true;
    final CoapEmptyMessage rst = CoapEmptyMessage.newRST(request);
    endpoint.sendEpEmptyMessage(this, rst);
  }

  /// Accept this exchange and therefore the request. Only if the request's
  /// type was a CON and the request has not been acknowledged
  /// yet, it sends an ACK to the client.
  void sendAccept() {
    assert(_origin == CoapOrigin.remote);
    if (request.type == CoapMessageType.con && !request.isAcknowledged) {
      request.isAcknowledged = true;
      final CoapEmptyMessage ack = CoapEmptyMessage.newACK(request);
      endpoint.sendEpEmptyMessage(this, ack);
    }
  }

  /// Sends the specified response over the same endpoint
  /// as the request has arrived.
  void sendResponse(CoapResponse resp) {
    resp.destination = request.source;
    response = resp;
    endpoint.sendEpResponse(this, response);
  }

  /// Attributes
  T get<T>(Object key) {
    return _attributes[key];
  }

  T getOrAdd<T>(Object key, Object value) {
    _attributes[key] = value;
    return _attributes[key];
  }

  T set<T>(Object key, Object value) {
    Object oldValue;
    if (_attributes.containsKey(key)) {
      oldValue = _attributes[key];
    }
    _attributes[key] = value;
    return oldValue;
  }

  Object remove(Object key) {
    return _attributes.remove(key);
  }
}

class CoapKeyId {
  CoapKeyId(int id, InternetAddress ep) {
    _id = id;
    _endpoint = ep;
    _hash = id * 31 + (ep == null ? 0 : ep.hashCode);
  }

  int _id;
  InternetAddress _endpoint;
  int _hash;

  int get getHashCode => _hash;

  /// Dart style
  int get hashCode => _hash;

  bool operator ==(Object obj) {
    if ((obj != null) && (obj is CoapKeyId)) {
      return (_id == obj._id) && (_endpoint == obj._endpoint);
    }
    return false;
  }

  String toString() {
    return "KeyID[$_id for $_endpoint]";
  }
}

class CoapKeyToken {
  CoapKeyToken(typed.Uint8Buffer token) {
    if (token == null) throw new ArgumentError.notNull("CoapKeyToken::token");
    _token = token;
    _hash = CoapByteArrayUtil.computeHash(_token);
  }

  typed.Uint8Buffer _token;
  int _hash;

  int get getHashCode => _hash;

  /// Dart style
  int get hashCode => _hash;

  bool operator ==(Object obj) {
    if ((obj != null) && (obj is CoapKeyToken)) {
      return _hash == obj.hashCode;
    }
    return false;
  }

  String toString() {
    return "KeyToken[${CoapByteArrayUtil.toHexString(_token)}]";
  }
}

class CoapKeyUri {
  CoapKeyUri(Uri uri, InternetAddress ep) {
    _uri = uri;
    _endpoint = ep;
    _hash = uri.hashCode * 31 + (ep == null ? 0 : ep.hashCode);
  }

  Uri _uri;
  InternetAddress _endpoint;
  int _hash;

  int get getHashCode => _hash;

  /// Dart style
  int get hashCode => _hash;

  bool operator ==(Object obj) {
    if ((obj != null) && (obj is CoapKeyUri)) {
      return (_uri == obj._uri) && (_endpoint == obj._endpoint);
    }
    return false;
  }

  String toString() {
    return "KeyUri[$_uri for $_endpoint]";
  }
}
