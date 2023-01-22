/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

import 'dart:io';

import 'package:collection/collection.dart';

import '../coap_message.dart';
import 'cache.dart';

/// This [Exception] is thrown when an unsupported URI scheme is encountered.
class UnsupportedProtocolException implements Exception {
  /// The unsupported Uri Scheme that was encountered.
  final String uriScheme;

  /// Constructor.
  UnsupportedProtocolException(this.uriScheme);

  @override
  String toString() =>
      '$runtimeType: Unsupported URI scheme $uriScheme encountered.';
}

/// Abstract networking class, allows different implementations for
/// UDP, TCP, test etc.
abstract class CoapINetwork {
  /// The initialization timeout
  static const Duration initTimeout = Duration(seconds: 10);

  /// The reinit period for open connections
  static Duration reinitPeriod = initTimeout + const Duration(seconds: 2);

  /// If the underlying socket is closed
  bool get isClosed;

  /// Sends a [coapMessage] over the socket.
  void sendMessage(final CoapMessage coapMessage, final Uri uri);

  /// Close the socket
  void close();
}

int _addressHashFunction(final Uri uri) => uri.host.hashCode;

final _addressCache = Cache<Uri, InternetAddress>(_addressHashFunction);

Future<InternetAddress?> _performLookup(final String host) async {
  final parsedAddress = InternetAddress.tryParse(host);
  if (parsedAddress != null) {
    return parsedAddress;
  }

  final foundAddresses = await InternetAddress.lookup(host);

  const validAddressTypes = [
    InternetAddressType.IPv4,
    InternetAddressType.IPv6,
  ];

  return foundAddresses
      .where((final address) => validAddressTypes.contains(address.type))
      .firstOrNull;
}

Future<InternetAddress> lookupHost(final Uri uri) async {
  final cachedAddress = _addressCache.retrieve(uri);

  if (cachedAddress != null) {
    return cachedAddress;
  }

  final lookupAddress = await _performLookup(uri.host);

  if (lookupAddress != null) {
    // TODO(JKRhb): Should a timeToLive be set here?
    _addressCache.save(uri, lookupAddress);
    return lookupAddress;
  }

  throw SocketException('Failed host lookup for $uri.');
}

void enableRetransmission(final CoapMessage coapMessage) {
  coapMessage.retransmissionCallback?.call();
}
