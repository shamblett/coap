/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 03/05/2017
 * Copyright :  S.Hamblett
 */

import 'dart:collection';

import 'package:meta/meta.dart';

const _request = 0;
const _success = 2;
const _clientError = 4;
const _serverError = 5;
const _signal = 7;

/// Models CoAP codes as described in [RFC 7252, section 3].
///
/// Can [decode] the codes empty messages, requests, responses, and signaling
/// messages.
///
/// [RFC 7252, section 3]: https://www.rfc-editor.org/rfc/rfc7252#section-3
@immutable
class CoapCode {
  static const codeByteShift = 5;
  static const stringPadding = 2;

  /// An 8-bit representation combining the [codeClass] and the [codeDetail].
  final int code;

  /// The code class of this [CoapCode] (in the range of 0 to 7).
  final int codeClass;

  /// The code detail of this [CoapCode] (in the range of 0 to 31).
  final int codeDetail;

  /// A human-readable description of this [ResponseCode].
  final String description;

  /// Code bit length
  static const int bitLength = 8;

  /// Checks whether this [CoapCode] indicates an empty message.
  bool get isEmpty => this == RequestMethod.empty.coapCode;

  /// Checks whether this [CoapCode] indicates a request message.
  bool get isRequest => codeClass == _request && !isEmpty;

  /// Checks whether this [CoapCode] indicates a response message.
  bool get isResponse => codeClass >= _success && codeClass <= _serverError;

  /// Checks whether this [CoapCode] represents a success response code.
  bool get isSuccess => codeClass == _success;

  /// Checks whether this [CoapCode] represents a client error response code.
  bool get isErrorResponse => codeClass == _clientError;

  /// Checks whether this [CoapCode] represents a server error response code.
  bool get isServerError => codeClass == _serverError;

  /// Checks whether this [CoapCode] indicates a signaling message.
  bool get isSignaling => codeClass == _signal;

  @override
  int get hashCode => code;

  const CoapCode(this.codeClass, this.codeDetail, this.description)
    : code = (codeClass << codeByteShift) + codeDetail;

  static CoapCode? decode(final int code) {
    if (code == 0) {
      return RequestMethod.empty.coapCode;
    }

    final codeClass = code >> codeByteShift;

    switch (codeClass) {
      case _request:
        return RequestMethod.decode(code)?.coapCode;
      case _success:
      case _clientError:
      case _serverError:
        return ResponseCode.decode(code)?.coapCode;
      case _signal:
        return SignalingCode.decode(code)?.coapCode;
    }

    return null;
  }

  @override
  bool operator ==(final Object other) =>
      other is CoapCode && code == other.code;

  @override
  String toString() {
    final formattedDetail = codeDetail.toString().padLeft(stringPadding, '0');
    return '$codeClass.$formattedDetail $description';
  }
}

/// Enumerates the currently specified values for request method codes.
///
/// Also includes the code for [empty] messages for now due to technical
/// reasons.
enum RequestMethod {
  /// Indicates an empty message
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  // TODO(JKRhb): Should become its own constant/class
  empty(0, 0, 'Empty'),

  /// The GET method
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  get(0, 01, 'GET'),

  /// The POST method
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  post(0, 02, 'POST'),

  /// The PUT method
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  put(0, 03, 'PUT'),

  /// The DELETE method
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  delete(0, 04, 'DELETE'),

  /// The FETCH method
  ///
  /// Defined in [RFC 8132](https://datatracker.ietf.org/doc/html/rfc8132).
  fetch(0, 05, 'FETCH'),

  /// The PATCH method
  ///
  /// Defined in [RFC 8132](https://datatracker.ietf.org/doc/html/rfc8132).
  patch(0, 06, 'PATCH'),

  /// The iPATCH method
  ///
  /// Defined in [RFC 8132](https://datatracker.ietf.org/doc/html/rfc8132).
  ipatch(0, 07, 'iPATCH');

  const RequestMethod(this.codeClass, this.codeDetail, this.description);

  /// The code class of this [RequestMethod] (always 0).
  final int codeClass;

  /// The code detail of this [RequestMethod] (in the range of 0 to 7).
  final int codeDetail;

  /// A human-readable description of this [RequestMethod].
  final String description;

  /// Returns the [CoapCode] representing this [RequestMethod].
  CoapCode get coapCode => CoapCode(codeClass, codeDetail, description);

  /// Returns the [RequestMethod] corresponding with a numeric [code]
  /// (if defined).
  static RequestMethod? decode(final int code) => _codeRegistry[code];

  /// Returns the [RequestMethod] corresponding with a given [CoapCode] (if
  /// defined).
  static RequestMethod? fromCoapCode(final CoapCode code) =>
      _codeRegistry[code.code];

  static final _codeRegistry = HashMap.fromEntries(
    values.map((final value) => MapEntry(value.coapCode.code, value)),
  );

  @override
  String toString() => coapCode.toString();
}

/// Enumerates the currently specified values for response codes (indicating
/// success, a client error, or a server error).
enum ResponseCode {
  /// 2.01 Created
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  created(2, 01, 'Created'),

  /// 2.02 Deleted
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  deleted(2, 02, 'Deleted'),

  /// 2.03 Valid
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  valid(2, 03, 'Valid'),

  /// 2.04 Changed
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  changed(2, 04, 'Changed'),

  /// 2.05 Content
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  content(2, 05, 'Content'),

  /// 2.31 Continue
  ///
  /// Defined in [RFC 7959](https://datatracker.ietf.org/doc/html/rfc7959).
  continues(2, 31, 'Continue'),

  /// 4.00 Bad Request
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  badRequest(4, 00, 'Bad Request'),

  /// 4.01 Unauthorized
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  unauthorized(4, 01, 'Unauthorized'),

  /// 4.02 Bad Option
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  badOption(4, 02, 'Bad Option'),

  /// 4.03 Forbidden
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  forbidden(4, 03, 'Forbidden'),

  /// 4.04 Not Found
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  notFound(4, 04, 'Not Found'),

  /// 4.05 Method Not Allowed
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  methodNotAllowed(4, 05, 'Method Not Allowed'),

  /// 4.06 Not Acceptable
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  notAcceptable(4, 06, 'Not Acceptable'),

  /// 4.08 Request Entity Incomplete
  ///
  /// Defined in [RFC 7959](https://datatracker.ietf.org/doc/html/rfc7959).
  requestEntityIncomplete(4, 08, 'Request Entity Incomplete'),

  /// 4.09 Conflict
  ///
  /// Defined in [RFC 8132](https://datatracker.ietf.org/doc/html/rfc8132).
  conflict(4, 09, 'Conflict'),

  /// 4.12 Precondition Failed
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  preconditionFailed(4, 12, 'Precondition Failed'),

  /// 4.13 Request Entity Too Large
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252) and
  /// [RFC 7959](https://datatracker.ietf.org/doc/html/rfc7959).
  requestEntityTooLarge(4, 13, 'Request Entity Too Large'),

  /// 4.15 Unsupported Content-Format
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  unsupportedMediaType(4, 15, 'Unsupported Content-Format'),

  /// 4.22 Unprocessable Entity
  ///
  /// Defined in [RFC 8132](https://datatracker.ietf.org/doc/html/rfc8132).
  unprocessableEntity(4, 22, 'Unprocessable Entity'),

  /// 4.29 Too Many Requests
  ///
  /// Defined in [RFC 8516](https://datatracker.ietf.org/doc/html/rfc8516).
  tooManyRequests(4, 29, 'Too Many Requests'),

  /// 5.00 Internal Server Error
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  internalServerError(5, 00, 'Internal Server Error'),

  /// 5.01 Not Implemented
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  notImplemented(5, 01, 'Not Implemented'),

  /// 5.02 Bad Gateway
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  badGateway(5, 02, 'Bad Gateway'),

  /// 5.03 Service Unavailable
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  serviceUnavailable(5, 03, 'Service Unavailable'),

  /// 5.04 Gateway Timeout
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  gatewayTimeout(5, 04, 'Gateway Timeout'),

  /// 5.05 Proxying Not Supported
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  proxyingNotSupported(5, 05, 'Proxying Not Supported'),

  /// 5.08 Hop Limit Reached
  ///
  /// Defined in [RFC 8768](https://datatracker.ietf.org/doc/html/rfc8768).
  hopLimitReached(5, 08, 'Hop Limit Reached');

  const ResponseCode(this.codeClass, this.codeDetail, this.description);

  /// The code class of this [ResponseCode] (either 2, 4, or 5).
  final int codeClass;

  /// The code detail of this [ResponseCode].
  final int codeDetail;

  /// A human-readable description of this [ResponseCode].
  final String description;

  /// Returns the [CoapCode] representing this [ResponseCode].
  CoapCode get coapCode => CoapCode(codeClass, codeDetail, description);

  /// Returns the [ResponseCode] corresponding with a numeric [code]
  /// (if defined).
  static ResponseCode? decode(final int code) => _codeRegistry[code];

  /// Returns the [ResponseCode] corresponding with a given [CoapCode] (if
  /// defined).
  static ResponseCode? fromCoapCode(final CoapCode code) =>
      _codeRegistry[code.code];

  static final _codeRegistry = HashMap.fromEntries(
    values.map((final value) => MapEntry(value.coapCode.code, value)),
  );

  @override
  String toString() => coapCode.toString();
}

/// Enumerates the currently specified values for signaling codes (see
/// [RFC 8323, section 5.1]).
///
/// [RFC 8323, section 5.1]: https://www.rfc-editor.org/rfc/rfc8323#section-5.1
enum SignalingCode {
  /// 7.01 CSM
  ///
  /// Defined in [RFC 8323](https://datatracker.ietf.org/doc/html/rfc8323).
  csm(7, 01, 'CSM'),

  /// 7.02 Ping
  ///
  /// Defined in [RFC 8323](https://datatracker.ietf.org/doc/html/rfc8323).
  ping(7, 02, 'Ping'),

  /// 7.03 Pong
  ///
  /// Defined in [RFC 8323](https://datatracker.ietf.org/doc/html/rfc8323).
  pong(7, 03, 'Pong'),

  /// 7.04 Release
  ///
  /// Defined in [RFC 8323](https://datatracker.ietf.org/doc/html/rfc8323).
  release(7, 04, 'Release'),

  /// 7.05 Abort
  ///
  /// Defined in [RFC 8323](https://datatracker.ietf.org/doc/html/rfc8323).
  abort(7, 05, 'Abort');

  const SignalingCode(this.codeClass, this.codeDetail, this.description);

  /// The code class of this [SignalingCode] (always 7).
  final int codeClass;

  /// The code detail of this [SignalingCode] (in the range of 1 to 5).
  final int codeDetail;

  /// A human-readable description of this [SignalingCode].
  final String description;

  /// Returns the [CoapCode] representing this [SignalingCode].
  CoapCode get coapCode => CoapCode(codeClass, codeDetail, description);

  /// Returns the [SignalingCode] corresponding with a numeric [code]
  /// (if defined).
  static SignalingCode? decode(final int code) => _codeRegistry[code];

  /// Returns the [SignalingCode] corresponding with a given [CoapCode] (if
  /// defined).
  static SignalingCode? fromCoapCode(final CoapCode code) =>
      _codeRegistry[code.code];

  static final _codeRegistry = HashMap.fromEntries(
    values.map((final value) => MapEntry(value.coapCode.code, value)),
  );

  @override
  String toString() => coapCode.toString();
}
