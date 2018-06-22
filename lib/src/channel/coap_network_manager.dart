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

  static List<CoapNetwork> _networks = new List<CoapNetwork>();

  /// Gets a new network, otherwise tries to find a cached network and returns that.
  static CoapNetwork getNetwork(InternetAddress address, int port) {
    final CoapNetwork network = new CoapNetworkUDP(address, port);
    if (_networks.contains(network)) {
      print("SJH - NM - same network");
      return _networks.where((e) => e == network).toList()[0];
    }
    print("SJH - NM  - creating network");
    network.bind();
    _networks.add(network);
    return network;
  }

  /// Removes a network
  static void removeNetwork(CoapNetwork network) {
    _networks.remove(network);
  }
}