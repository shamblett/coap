/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

import 'package:meta/meta.dart';
import 'package:typed_data/typed_buffers.dart';

import 'coap_code.dart';
import 'coap_message.dart';
import 'coap_message_type.dart';
import 'coap_request.dart';
import 'option/option.dart';
import 'option/uri_converters.dart';

/// Represents a CoAP response to a CoAP request.
/// A response is either a piggy-backed response with type ACK
/// or a separate response with type CON or NON.
class CoapResponse extends CoapMessage {
  /// Initializes a response message.
  CoapResponse(
    this.responseCode,
    final CoapMessageType type, {
    final Uri? location,
    super.payload,
  }) : location = location ?? Uri(path: '/'),
       super(responseCode.coapCode, type);

  final ResponseCode responseCode;

  /// Relative [Uri] that consists either of an absolute path, a query string,
  /// or both.
  ///
  /// May be included in a 2.01 (Created) response to indicate the location of
  /// the resource created as the result of a POST request (see
  /// [RFC 7252, Section 5.8.2]).
  ///
  /// The location is supposed to be resolved relative to the request URI.
  ///
  /// [RFC 7252, Section 5.8.2]: https://www.rfc-editor.org/rfc/rfc7252#section-5.8.2
  final Uri location;

  @override
  List<Option<Object?>> getAllOptions() =>
      locationToOptions(location)..addAll(super.getAllOptions());

  /// Status code as a string
  String get statusCodeString => code.toString();

  Uint8Buffer? _multicastToken;

  /// The initial multicast token, used for matching responses
  Uint8Buffer? get multicastToken => _multicastToken;
  @internal
  set multicastToken(final Uint8Buffer? val) => _multicastToken = val;

  Duration? _rtt;

  bool get isSuccess => code.isSuccess;

  /// The Round-Trip Time of this response.
  Duration? get rtt => _rtt;
  @internal
  set rtt(final Duration? val) => _rtt = val;

  bool _last = true;

  /// A value indicating whether this response is the last
  /// response of an exchange.
  bool get last => _last;
  @internal
  set last(final bool val) => _last = val;

  @override
  String toString() => '\n<<< Response Message >>> ${super.toString()}';

  /// Creates a response to the specified request with the
  /// specified response code.
  /// The destination endpoint of the response is the source
  /// endpoint of the request.
  /// The response has the same token as the request.
  /// Type and ID are usually set automatically by the ReliabilityLayer>.
  factory CoapResponse.createResponse(
    final CoapRequest request,
    final ResponseCode statusCode,
    final CoapMessageType type, {
    final Uri? location,
    final Iterable<int>? payload,
  }) =>
      CoapResponse(statusCode, type, location: location, payload: payload)
        ..destination = request.source
        ..token = request.token;

  CoapResponse.fromParsed(
    this.responseCode, {
    required final CoapMessageType type,
    required final int id,
    required final Uint8Buffer token,
    required final List<Option<Object?>> options,
    required final Uint8Buffer? payload,
    required final bool hasUnknownCriticalOption,
    required final bool hasFormatError,
    final Uri? location,
  }) : location = location ?? Uri(path: '/'),
       super.fromParsed(
         responseCode.coapCode,
         type,
         id: id,
         token: token,
         options: options,
         hasUnknownCriticalOption: hasUnknownCriticalOption,
         hasFormatError: hasFormatError,
         payload: payload,
       );
}
