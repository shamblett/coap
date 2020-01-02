/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

// ignore_for_file: omit_local_variable_types
// ignore_for_file: unnecessary_final
// ignore_for_file: cascade_invocations
// ignore_for_file: avoid_annotating_with_dynamic
// ignore_for_file: avoid_types_on_closure_parameters

/// Endpoint manager
class CoapEndpointManager {
  /// Default spec
  static void getDefaultSpec() {
    final CoapConfig config = CoapConfig.inst;
    config.spec ??= CoapDraft18();
  }

  /// Default endpoint
  static CoapIEndPoint getDefaultEndpoint(CoapIEndPoint endpoint) {
    final CoapConfig config = CoapConfig.inst;
    config.spec ??= CoapDraft18();
    config.defaultPort = config.spec.defaultPort;
    final CoapIChannel channel =
        CoapUDPChannel(endpoint.localEndpoint, config.defaultPort);
    final CoapEndPoint ep = CoapEndPoint(channel, config);
    ep.start();
    return ep;
  }
}
