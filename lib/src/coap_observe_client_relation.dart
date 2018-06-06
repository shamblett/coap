/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 05/06/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Represents a CoAP observe relation between a CoAP client and a resource on a server.
/// Provides a simple API to check whether a relation has successfully established and
/// to cancel or refresh the relation.
class CoapObserveClientRelation extends Object with events.EventDetector {
  CoapObserveClientRelation(CoapRequest request, CoapIEndPoint endpoint,
      CoapConfig config) {
    _config = config;
    _request = request;
    _endpoint = endpoint;
    _orderer = new CoapObserveNotificationOrderer(config);
    listen(_request, CoapReregisteringEvent, _onReregister);
  }

  CoapConfig _config;
  CoapRequest _request;

  CoapRequest get request => _request;
  CoapIEndPoint _endpoint;
  bool cancelled;
  CoapResponse current;
  CoapObserveNotificationOrderer _orderer;

  CoapObserveNotificationOrderer get orderer => _orderer;

  void reactiveCancel() {
    _request.isCancelled = true;
    cancelled = true;
  }

  void proactiveCancel() {
    final CoapRequest cancel = CoapRequest.newGet();
    // Copy options, but set Observe to cancel
    cancel.setOptions(_request.getSortedOptions());
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

  void _onReregister(events.Event e) {
    // Reset orderer to accept any sequence number since server might have rebooted
    _orderer = new CoapObserveNotificationOrderer(_config);
  }
}
