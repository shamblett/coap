/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// The Coap package API
class Coap {
  /// Construction
  /// Default is to use UDP
  Coap() {
    _network = new NetworkUDP();
  }

  /// The network interface to use
  Network _network;

  NetworkUDP get udpNetwork => _network as NetworkUDP;

  Network get network => _network;

  set udpNetwork(NetworkUDP net) => _network = net;

  set network(Network net) => _network = net;

  /// Port, defaults to 5683
  int port = 5683;

  /// The address
  InternetAddress address;
}
