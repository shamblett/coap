/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 20/06/2018
 * Copyright :  S.Hamblett
 */

part of coap;

// ignore_for_file: omit_local_variable_types
// ignore_for_file: unnecessary_final
// ignore_for_file: cascade_invocations
// ignore_for_file: avoid_print
// ignore_for_file: avoid_types_on_closure_parameters

// ignore: avoid_classes_with_only_static_members
/// A network management/caching class, allows already
/// bound endpoints to be reused without instantiating them again.
class CoapNetworkManagement {
  static final List<CoapINetwork> _networks = <CoapINetwork>[];

  /// Gets a new network, otherwise tries to find a cached network
  /// and returns that.
  static Future<CoapINetwork> getNetwork(
      CoapInternetAddress address, int port) async {
    final Completer<CoapINetwork> completer = Completer<CoapINetwork>();
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
