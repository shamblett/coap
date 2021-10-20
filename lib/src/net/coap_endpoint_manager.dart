/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Endpoint manager
class CoapEndpointManager {
  /// Default spec
  static void getDefaultSpec() {
    final config = DefaultCoapConfig.inst!;
    config.spec ??= CoapDraft18();
  }

  /// Default endpoint
  static CoapIEndPoint getDefaultEndpoint(CoapIEndPoint endpoint,
      {required String namespace}) {
    final config = DefaultCoapConfig.inst!;
    config.spec ??= CoapDraft18();
    config.defaultPort = config.spec!.defaultPort;
    final CoapIChannel channel = CoapUDPChannel(
        endpoint.localEndpoint, config.defaultPort,
        namespace: namespace);
    final ep = CoapEndPoint(channel, config, namespace: namespace);
    ep.start();
    return ep;
  }
}
