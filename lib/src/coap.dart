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
    _network = new CoapNetworkUDP();
  }

  /// The network interface to use
  CoapNetwork _network;

  CoapNetworkUDP get udpNetwork => _network as CoapNetworkUDP;

  CoapNetwork get network => _network;

  set udpNetwork(CoapNetworkUDP net) => _network = net;

  set network(CoapNetwork net) => _network = net;

  /// Port, defaults to 5683
  int port = 5683;

  /// The address
  InternetAddress address;
}
