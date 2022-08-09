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

/// Represents a CoAP response to a CoAP request.
/// A response is either a piggy-backed response with type ACK
/// or a separate response with type CON or NON.
class CoapResponse extends CoapMessage {
  /// Initializes a response message.
  CoapResponse(super.code, super.type) {
    if (!code.isResponse) {
      throw ArgumentError('Expected CoAP response code, got $code');
    }
  }

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
    final CoapCode statusCode,
    final CoapMessageType type,
  ) =>
      CoapResponse(statusCode, type)
        ..destination = request.source
        ..token = request.token;

  CoapResponse.fromParsed({
    required final CoapCode coapCode,
    required final CoapMessageType type,
    required final int id,
    required final Uint8Buffer token,
    required final List<Option<Object?>> options,
    required final Uint8Buffer? payload,
    required final bool hasUnknownCriticalOption,
    required final bool hasFormatError,
  }) : super.fromParsed(
          coapCode,
          type,
          id: id,
          token: token,
          options: options,
          hasUnknownCriticalOption: hasUnknownCriticalOption,
          hasFormatError: hasFormatError,
          payload: payload,
        );
}
