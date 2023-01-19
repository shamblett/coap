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
import 'option/string_option.dart';

/// Represents a CoAP response to a CoAP request.
/// A response is either a piggy-backed response with type ACK
/// or a separate response with type CON or NON.
class CoapResponse extends CoapMessage {
  /// Initializes a response message.
  CoapResponse(this.responseCode, final CoapMessageType type)
      : super(responseCode.coapCode, type);

  final ResponseCode responseCode;

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
    final CoapMessageType type,
  ) =>
      CoapResponse(statusCode, type)
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
  }) : super.fromParsed(
          responseCode.coapCode,
          type,
          id: id,
          token: token,
          options: options,
          hasUnknownCriticalOption: hasUnknownCriticalOption,
          hasFormatError: hasFormatError,
          payload: payload,
        );

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
  Uri get location {
    final path = getOptions<LocationPathOption>()
        .map((final option) => option.pathSegment)
        .join();
    final queryParameters = Map.fromEntries(
      getOptions<LocationQueryOption>().map(
        (final option) => option.queryParameter,
      ),
    );

    return Uri(
      path: path.isNotEmpty ? path : '/',
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );
  }

  /// Location path as a string
  String get locationPath => location.path;

  /// Set the location path from a string
  set locationPath(final String fullPath) {
    clearLocationPath();

    var trimmedPath = fullPath;

    if (fullPath.startsWith('/')) {
      trimmedPath = fullPath.substring(1);
    }

    trimmedPath.split('/').forEach(addLocationPath);
  }

  /// Location paths
  List<LocationPathOption> get locationPaths =>
      getOptions<LocationPathOption>();

  /// Add a location path
  void addLocationPath(final String path) =>
      addOption(LocationPathOption(path));

  /// Remove a location path
  void removelocationPath(final String path) =>
      removeOptionWhere((final element) => element.value == path);

  /// Clear location path
  void clearLocationPath() => removeOptions<LocationPathOption>();

  /// Location query
  String get locationQuery => location.query;

  /// Set a location query
  set locationQuery(final String fullQuery) {
    var trimmedQuery = fullQuery;
    if (trimmedQuery.startsWith('?')) {
      trimmedQuery = trimmedQuery.substring(1);
    }
    clearLocationQuery();
    trimmedQuery.split('&').forEach(addLocationQuery);
  }

  /// Location queries
  List<LocationQueryOption> get locationQueries =>
      getOptions<LocationQueryOption>();

  /// Add a location query
  void addLocationQuery(final String query) =>
      addOption(LocationQueryOption(query));

  /// Remove a location query
  void removeLocationQuery(final String query) {
    removeOptionWhere(
      (final element) =>
          element is LocationQueryOption && element.value == query,
    );
  }

  /// Clear location  queries
  void clearLocationQuery() => removeOptions<LocationQueryOption>();
}
