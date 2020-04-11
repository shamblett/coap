/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 20/06/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// A network management/caching class, allows already
/// bound endpoints to be reused without instantiating them again.
class CoapNetworkManagement {
  static final List<CoapINetwork> _networks = <CoapINetwork>[];

  /// Gets a new network, otherwise tries to find a cached network
  /// and returns that.
  static Future<CoapINetwork> getNetwork(
      CoapInternetAddress address, int port) async {
    final completer = Completer<CoapINetwork>();
    final CoapINetwork network = CoapNetworkUDP(address, port);
    if (_networks.contains(network)) {
      completer.complete(
          _networks.where((CoapINetwork e) => e == network).toList()[0]);
    } else {
      network.bind();
      _networks.add(network);
      completer.complete(network);
    }
    return completer.future;
  }

  /// Removes a network
  static void removeNetwork(CoapINetwork network) {
    _networks.remove(network);
  }
}
