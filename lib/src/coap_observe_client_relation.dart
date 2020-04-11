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
      CoapRequest request, CoapIEndPoint endpoint, DefaultCoapConfig config) {
    _config = config;
    _request = request;
    _endpoint = endpoint;
    _orderer = CoapObserveNotificationOrderer(config);
    _eventBus.on<CoapReregisteringEvent>().listen(_onReregister);
  }

  DefaultCoapConfig _config;
  CoapRequest _request;
  final CoapEventBus _eventBus = CoapEventBus();

  /// Request
  CoapRequest get request => _request;
  CoapIEndPoint _endpoint;

  /// Cancelled
  bool cancelled;

  /// Current response
  CoapResponse current;
  CoapObserveNotificationOrderer _orderer;

  /// Orderer
  CoapObserveNotificationOrderer get orderer => _orderer;

  /// Cancel after the fact
  void reactiveCancel() {
    _request.isCancelled = true;
    cancelled = true;
  }

  /// Cancel
  void proactiveCancel() {
    final cancel = CoapRequest.newGet();
    // Copy options, but set Observe to cancel
    cancel.setOptions(_request.getAllOptions());
    cancel.markObserveCancel();
    // Use same Token
    cancel.token = _request.token;
    cancel.destination = _request.destination;

    // Dispatch final response to the same message observers
    cancel.copyEventHandler(_request);

    cancel.sendWithEndpoint(_endpoint);
    // Cancel old ongoing request
    _request.isCancelled = true;
    cancelled = true;
  }

  void _onReregister(CoapReregisteringEvent e) {
    // Reset orderer to accept any sequence number since server
    // might have rebooted.
    _orderer = CoapObserveNotificationOrderer(_config);
  }
}
