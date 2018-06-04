/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/06/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Builds up the stack of CoAP layers
/// that process the CoAP protocol.
class CoapStack extends CoapLayerStack {
  /// Instantiates.
  CoapStack(CoapConfig config) {
    this.addLast("Observe", new CoapObserveLayer(config));
    this.addLast("Blockwise", new CoapBlockwiseLayer(config));
    this.addLast("Token", new CoapTokenLayer(config));
    this.addLast("Reliability", new CoapReliabilityLayer(config));
  }

  /// Sets the <see cref="IExecutor"/> for all layers.
  CoapIExecutor _executor;

  CoapIExecutor get executor => _executor;

  set(CoapIExecutor value) {
    for (CoapEntry entry in this.getAll()) {
      entry.filter.executor = value;
    }
  }
}
