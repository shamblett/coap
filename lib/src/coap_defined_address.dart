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
  static const String allCOAPIPV4 = '224.0.1.187';

  /// Multicast IPV6
  static const String allCOAPIPV6 = '[FF0X::FD]';
}
