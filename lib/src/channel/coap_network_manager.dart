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
  static List<CoapNetwork> _networks = List<CoapNetwork>();

  /// Gets a new network, otherwise tries to find a cached network and returns that.
  static Future<CoapNetwork> getNetwork(InternetAddress address,
      int port) async {
    final Completer<CoapNetwork> completer = Completer<CoapNetwork>();
    final CoapNetwork network = CoapNetworkUDP(address, port);
    if (_networks.contains(network)) {
      completer.complete(
          _networks.where((CoapNetwork e) => e == network).toList()[0]);
    } else {
      await network.bind();
      _networks.add(network);
      completer.complete(network);
    }
    return completer.future;
  }

  /// Removes a network
  static void removeNetwork(CoapNetwork network) {
    _networks.remove(network);
  }
}
