/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 05/06/2018
 * Copyright :  S.Hamblett
 */

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'coap_request.dart';
import 'event/coap_event_bus.dart';

/// Represents a CoAP observe relation between a CoAP client and a
/// resource on a server.
/// Provides a simple API to check whether a relation has successfully
/// established and to cancel or refresh the relation.
class CoapObserveClientRelation {
  /// Construction
  CoapObserveClientRelation(this._request);

  /// Response stream
  Stream<CoapRespondEvent> get stream => _request.eventBus!
      .on<CoapRespondEvent>()
      .where((CoapRespondEvent e) => e.resp.token!.equals(_request.token!))
      .takeWhile((_) => !_request.isTimedOut && !_request.isCancelled);

  final CoapRequest _request;

  bool _cancelled = false;

  /// Cancelled
  bool get isCancelled => _cancelled;
  @protected
  set isCancelled(bool val) {
    _request.isCancelled = val;
    _cancelled = val;
  }

  /// Create a cancellation request
  @protected
  CoapRequest newCancel() {
    final cancel = CoapRequest.newGet();
    // Copy options, but set Observe to cancel
    cancel.setOptions(_request.getAllOptions());
    cancel.observe = 1;
    // Use same Token
    cancel.token = _request.token;
    cancel.destination = _request.destination;

    // Dispatch final response to the same message observers
    cancel.copyEventHandler(_request);

    return cancel;
  }
}
