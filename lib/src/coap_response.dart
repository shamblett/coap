/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

import 'package:meta/meta.dart';

import 'coap_code.dart';
import 'coap_message.dart';
import 'coap_request.dart';

/// Represents a CoAP response to a CoAP request.
/// A response is either a piggy-backed response with type ACK
/// or a separate response with type CON or NON.
class CoapResponse extends CoapMessage {
  /// Initializes a response message.
  CoapResponse(this._statusCode) : super(code: _statusCode);

  final int _statusCode;

  /// The response status code.
  int get statusCode => _statusCode;

  /// Status code as a string
  String get statusCodeString => CoapCode.codeToString(_statusCode);

  Duration? _rtt;

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
  CoapResponse.createResponse(
    final CoapRequest request,
    this._statusCode,
  ) {
    destination = request.source;
    token = request.token;
  }
}
