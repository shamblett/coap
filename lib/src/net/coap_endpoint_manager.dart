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
    config.spec ??= CoapRfc7252();
  }

  static CoapIChannel determineCoapChannel(
      String uriScheme, CoapInternetAddress? endpoint, int port,
      {required String namespace, required DefaultCoapConfig config}) {
    switch (uriScheme) {
      case CoapConstants.uriScheme:
        return CoapUDPChannel(endpoint, port, uriScheme,
            namespace: namespace, config: config);
      default:
        throw UnsupportedProtocolException(uriScheme);
    }
  }

  static int _getPortForUriScheme(String scheme, CoapISpec spec) {
    switch (scheme) {
      case CoapConstants.uriScheme:
        return spec.defaultPort;
      case CoapConstants.secureUriScheme:
        return spec.defaultSecurePort;
      default:
        throw UnsupportedProtocolException(scheme);
    }
  }

  /// Default endpoint
  static CoapIEndPoint getDefaultEndpoint(String scheme, CoapIEndPoint endpoint,
      {required String namespace}) {
    final config = DefaultCoapConfig.inst!;
    config.spec ??= CoapRfc7252();
    config.defaultPort = config.spec!.defaultPort;
    config.defaultSecurePort = config.spec!.defaultSecurePort;

    final port = _getPortForUriScheme(scheme, config.spec!);
    final channel = determineCoapChannel(scheme, endpoint.localEndpoint, port,
        namespace: namespace, config: config);
    final ep = CoapEndPoint(channel, config, namespace: namespace);
    ep.start();
    return ep;
  }
}
