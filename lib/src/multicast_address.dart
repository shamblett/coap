/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 05/06/2018
 * Copyright :  S.Hamblett
 */

import 'dart:io';

/// Defines well-known multicast addresses from RFC 7252 and RFC 9176.
///
/// This enum's [toString] method returns the [address] field. In the case of
/// IPv6 addresses, the [address] string gets wrapped in square brackets. This
/// makes it easier to use the enum values in URI strings, such as the
/// following:
///
/// ```dart
/// final uri = Uri.parse('coap://${MulticastAddress.allNodesLinkLocalIPV6}');
/// ```
enum MulticastAddress {
  // Multicast IPV4
  allRoutersIPV4('224.0.0.2'),
  allSystemsIPV4('224.0.0.1'),
  allCOAPNodesIPV4('224.0.1.187'),

  /// "All CoRE Resource Directories" IPv4 multicast address.
  ///
  /// Specified in [RFC 9176, section 9.5].
  ///
  /// [RFC 9176, section 9.5]: https://datatracker.ietf.org/doc/html/rfc9176#section-9.5
  allCoreRDsIPv4('224.0.1.190'),

  // Multicast IPV6
  allRoutersIPV6('FF01::2'),
  allNodesIPV6('FF01::1'),
  allRoutersLinkLocalIPV6('FF02::2'),
  allNodesLinkLocalIPV6('FF02::1'),
  allRoutersSiteLocalIPV6('FF05::2'),
  allCOAPNodesIPV6('FF01::FD'),
  allCOAPNodesLinkLocalIPV6('FF02::FD'),
  allCOAPNodesSiteLocalIPV6('FF05::FD'),

  /// "All CoRE Resource Directories" IPv6 multicast address.
  ///
  /// Specified in [RFC 9176, section 9.5].
  ///
  /// [RFC 9176, section 9.5]: https://datatracker.ietf.org/doc/html/rfc9176#section-9.5
  allCoreRDsIPv6('FF01::FE'),

  /// "All CoRE Resource Directories" IPv6 link-local multicast address.
  ///
  /// Specified in [RFC 9176, section 9.5].
  ///
  /// [RFC 9176, section 9.5]: https://datatracker.ietf.org/doc/html/rfc9176#section-9.5
  allCoreRDsLinkLocalIPv6('FF02::FE'),

  /// "All CoRE Resource Directories" IPv6 site-local multicast address.
  ///
  /// Specified in [RFC 9176, section 9.5].
  ///
  /// [RFC 9176, section 9.5]: https://datatracker.ietf.org/doc/html/rfc9176#section-9.5
  allCoreRDsSiteLocalIPv6('FF05::FE');

  /// Constructor.
  const MulticastAddress(this.address);

  /// A string representation of this CoAP [MulticastAddress].
  final String address;

  /// Generates an [InternetAddress] object representing the [address].
  InternetAddress get internetAddress => InternetAddress(address);

  /// The [InternetAddressType] of this [MulticastAddress].
  ///
  /// Returns either [InternetAddressType.IPv4] or [InternetAddressType.IPv6].
  InternetAddressType get addressType => internetAddress.type;

  @override
  String toString() {
    if (addressType == InternetAddressType.IPv6) {
      return '[$address]';
    }

    return address;
  }
}
