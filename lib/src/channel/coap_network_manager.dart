/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 20/06/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// This [Exception] is thrown when an unsupported URI scheme is encountered.
class UnsupportedProtocolException implements Exception {
  /// The error message of this [Exception].
  String get message => 'Unsupported URI scheme $uriScheme encountered.';

  /// The unsupported Uri Scheme that was encountered.
  final String uriScheme;

  /// Constructor.
  UnsupportedProtocolException(this.uriScheme);
}

/// A network management/caching class, allows already
/// bound endpoints to be reused without instantiating them again.
class CoapNetworkManagement {
  static final List<CoapINetwork> _networks = <CoapINetwork>[];

  /// Gets a new network, otherwise tries to find a cached network
  /// and returns that.
  static CoapINetwork getNetwork(
      CoapInternetAddress address, int port, String scheme,
      {required String namespace, required DefaultCoapConfig config}) {
    final CoapINetwork network;

    switch (scheme) {
      case CoapConstants.uriScheme:
        {
          network = CoapNetworkUDP(address, port, namespace: namespace);
          break;
        }
      default:
        throw UnsupportedProtocolException(scheme);
    }

    if (_networks.contains(network)) {
      return _networks.where((CoapINetwork e) => e == network).toList()[0];
    } else {
      _networks.add(network);
      return network;
    }
  }

  /// Removes a network
  static void removeNetwork(CoapINetwork network) {
    _networks.remove(network);
  }
}
