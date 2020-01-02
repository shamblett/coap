/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 05/06/2018
 * Copyright :  S.Hamblett
 */

part of coap;

// ignore_for_file: omit_local_variable_types
// ignore_for_file: unnecessary_final
// ignore_for_file: cascade_invocations
// ignore_for_file: avoid_print
// ignore_for_file: avoid_types_on_closure_parameters
// ignore_for_file: avoid_returning_this
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes
// ignore_for_file: prefer_null_aware_operators

/// Represents a CoAP observe relation between a CoAP client and a
/// resource on a server.
/// Provides a simple API to check whether a relation has successfully
/// established and to cancel or refresh the relation.
class CoapObserveClientRelation {
  /// Construction
  CoapObserveClientRelation(
      CoapRequest request, CoapIEndPoint endpoint, CoapConfig config) {
    _config = config;
    _request = request;
    _endpoint = endpoint;
    _orderer = CoapObserveNotificationOrderer(config);
    _eventBus.on<CoapReregisteringEvent>().listen(_onReregister);
  }

  CoapConfig _config;
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
    final CoapRequest cancel = CoapRequest.newGet();
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
