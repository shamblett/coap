/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 05/06/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Represents a CoAP observe relation between a CoAP client and a
/// resource on a server.
/// Provides a simple API to check whether a relation has successfully
/// established and to cancel or refresh the relation.
class CoapObserveClientRelation {
  /// Construction
  CoapObserveClientRelation(
      CoapRequest request, CoapIEndPoint? endpoint, DefaultCoapConfig config,
      {required String namespace}) {
    _config = config;
    _request = request;
    _eventBus = CoapEventBus(namespace: namespace);
    _orderer = CoapObserveNotificationOrderer(config);
    _eventBus.on<CoapReregisteringEvent>().listen(_onReregister);
  }

  /// Response stream
  Stream<CoapRespondEvent> get stream => _eventBus.on<CoapRespondEvent>().where(
      (CoapRespondEvent e) => e.resp!.tokenString == _request!.tokenString);

  DefaultCoapConfig? _config;
  CoapRequest? _request;
  late final CoapEventBus _eventBus;

  /// Request
  CoapRequest? get request => _request;

  CoapObserveNotificationOrderer? _orderer;

  /// Orderer
  CoapObserveNotificationOrderer? get orderer => _orderer;

  bool _cancelled = false;

  /// Cancelled
  bool get isCancelled => _cancelled;
  @protected
  set isCancelled(bool val) {
    _request!.isCancelled = val;
    _cancelled = val;
  }

  /// Create a cancellation request
  @protected
  CoapRequest newCancel() {
    final cancel = CoapRequest.newGet();
    // Copy options, but set Observe to cancel
    cancel.setOptions(_request!.getAllOptions());
    cancel.observe = 1;
    // Use same Token
    cancel.token = _request!.token;
    cancel.destination = _request!.destination;

    // Dispatch final response to the same message observers
    cancel.copyEventHandler(_request!);

    return cancel;
  }

  void _onReregister(CoapReregisteringEvent e) {
    // Reset orderer to accept any sequence number since server
    // might have rebooted.
    _orderer = CoapObserveNotificationOrderer(_config);
  }
}
