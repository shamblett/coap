/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/06/2018
 * Copyright :  S.Hamblett
 */

import '../coap_config.dart';
import 'coap_blockwise_layer.dart';
import 'coap_layer_stack.dart';
import 'coap_observe_layer.dart';
import 'coap_reliability_layer.dart';
import 'coap_token_layer.dart';

/// Builds up the stack of CoAP layers
/// that process the CoAP protocol.
class CoapStack extends CoapLayerStack {
  /// Instantiates.
  CoapStack(final DefaultCoapConfig config) {
    addLast('Observe', CoapObserveLayer(config));
    addLast('Blockwise', CoapBlockwiseLayer(config));
    addLast('Token', CoapTokenLayer(config));
    addLast('Reliability', CoapReliabilityLayer(config));
  }
}
