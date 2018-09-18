/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

class CoapEndpointManager {
  static void getDefaultSpec() {
    final CoapConfig config = CoapConfig.inst;
    if (config.spec == null) {
      config.spec = new CoapDraft18();
    }
  }

  static CoapIEndPoint getDefaultEndpoint(CoapIEndPoint endpoint) {
    final CoapConfig config = CoapConfig.inst;
    if (config.spec == null) {
      config.spec = new CoapDraft18();
    }
    config.defaultPort = config.spec.defaultPort;
    final CoapIChannel channel =
        new CoapUDPChannel(endpoint.localEndpoint, config.defaultPort);
    final CoapEndPoint ep = new CoapEndPoint(channel, config);
    ep.start();
    return ep;
  }
}
