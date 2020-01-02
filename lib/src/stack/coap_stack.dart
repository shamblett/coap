/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/06/2018
 * Copyright :  S.Hamblett
 */

part of coap;

// ignore_for_file: omit_local_variable_types
// ignore_for_file: unnecessary_final

/// Builds up the stack of CoAP layers
/// that process the CoAP protocol.
class CoapStack extends CoapLayerStack {
  /// Instantiates.
  CoapStack(CoapConfig config) {
    addLast('Observe', CoapObserveLayer(config));
    addLast('Blockwise', CoapBlockwiseLayer(config));
    addLast('Token', CoapTokenLayer(config));
    addLast('Reliability', CoapReliabilityLayer(config));
  }

  CoapIExecutor _executor;

  /// The IExecutor for all layers.
  CoapIExecutor get executor => _executor;

  set executor(CoapIExecutor value) {
    for (final CoapEntry<dynamic, dynamic> entry in getAll()) {
      entry.filter.executor = value;
    }
  }
}
