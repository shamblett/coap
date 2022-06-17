/*
 * Package : Coap
 * Author : Jan Romann <jan.romann@uni-bremen.de>
 * Date   : 05/22/2022
 * Copyright :  Jan Romann
 */

/// Generic class for [Exception]s that are thrown when a CoAP request fails.
abstract class CoapRequestException implements Exception {
  String get failReason;

  CoapRequestException();

  @override
  String toString() => '$runtimeType: $failReason';
}

/// This [Exception] is thrown when a CoAP request has timed out.
class CoapRequestTimeoutException extends CoapRequestException {
  /// The number of retransmits after which the request timed out.
  final int retransmits;

  CoapRequestTimeoutException(this.retransmits);

  @override
  String get failReason => 'Request timed out after $retransmits retransmits.';
}

/// This [Exception] is thrown when a CoAP request has timed out.
class CoapRequestCancellationException extends CoapRequestException {
  @override
  final failReason = 'Request has been cancelled.';
}
