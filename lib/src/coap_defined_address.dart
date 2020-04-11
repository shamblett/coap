/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 05/06/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Defines standard addresses from RFC7252
class CoapDefinedAddress {
  /// Multicast IPV4
  static const String allRoutersIPV4 = '224.0.0.2';
  static const String allSystemsIPV4 = '224.0.0.1';
  static const String allCOAPNodesIPV4 = '224.0.1.187';

  /// Multicast IPV6
  static const String allRoutersIPV6 = '[FF01::2]';
  static const String allNodesIPV6 = '[FF01::1]';
  static const String allRoutersLinkLocalIPV6 = '[FF02::2]';
  static const String allNodesLinkLocalIPV6 = '[FF02::1]';
  static const String allRoutersSiteLocalIPV6 = '[FF05::2]';
  static const String allCOAPNodesIPV6 = '[FF01::FD]';
  static const String allCOAPNodesLinkLocalIPV6 = '[FF02::FD]';
  static const String allCOAPNodesSiteLocalIPV6 = '[FF05::FD]';
}
