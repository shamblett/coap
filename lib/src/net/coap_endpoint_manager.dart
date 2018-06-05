/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

class CoapEndpointManager {
  static CoapIEndPoint getDefaultEndPoint() {
    final CoapConfig config = CoapConfig.inst;
    if (config.spec == null) {
      config.spec = new CoapDraft18();
    }
    config.defaultPort = config.spec.defaultPort;
    final CoapEndPoint ep =
        new CoapEndPoint.withPort(config.defaultPort, config);
    ep.start();
    return ep;
  }
}
