// ignore_for_file: avoid_classes_with_only_static_members

/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 03/05/2017
 * Copyright :  S.Hamblett
 */

import 'dart:collection';

enum CoapCode {
  /// Indicates an empty message
  ///
  /// Defined in [RFC 7252](https://datatracker.ietf.org/doc/html/rfc7252).
  empty(0, 00, 'Empty'),

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
  requestEntityIncomplete(
    4,
    08,
    'Request Entity Incomplete',
  ),

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
  requestEntityTooLarge(
    4,
    13,
    'Request Entity Too Large',
  ),

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

  const CoapCode(
    this.codeClass,
    this.codeDetail,
    this.description,
  ) : code = (codeClass << 5) + codeDetail;

  static CoapCode? decode(final int code) => _codeRegistry[code];

  static final _codeRegistry = HashMap.fromEntries(
    values.map((final value) => MapEntry(value.code, value)),
  );

  final int code;

  final int codeClass;

  final int codeDetail;

  final String description;

  @override
  String toString() {
    final formattedDetail = codeDetail.toString().padLeft(2, '0');
    return '$codeClass.$formattedDetail $description';
  }

  /// Checks whether this [CoapCode] indicates an empty message.
  bool get isEmpty => this == empty;

  /// Checks whether this [CoapCode] indicates a request message.
  bool get isRequest => codeClass == 0 && !isEmpty;

  /// Checks whether this [CoapCode] indicates a response message.
  bool get isResponse => codeClass >= 2 && codeClass <= 5;

  /// Checks whether this [CoapCode] represents a success response code.
  bool get isSuccess => codeClass == 2;

  /// Checks whether this [CoapCode] represents a client error response code.
  bool get isErrorResponse => codeClass == 4;

  /// Checks whether this [CoapCode] represents a server error response code.
  bool get isServerError => codeClass == 5;
}
