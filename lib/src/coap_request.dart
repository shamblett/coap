/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

import 'dart:io';

import 'package:meta/meta.dart';
import 'package:typed_data/typed_buffers.dart';

import 'coap_code.dart';
import 'coap_constants.dart';
import 'coap_message.dart';
import 'coap_message_type.dart';
import 'net/endpoint.dart';
import 'option/integer_option.dart';
import 'option/option.dart';
import 'option/string_option.dart';

/// This class describes the functionality of a CoAP Request as
/// a subclass of a CoAP Message. It provides:
/// 1. operations to answer a request by a response using respond()
/// 2. different ways to handle incoming responses:
/// receiveResponse() or Response event.
class CoapRequest extends CoapMessage {
  /// Initializes a request message.
  /// Defaults to confirmable
  CoapRequest(this.method, final Uri uri, {final bool confirmable = true})
      : super(
          method.coapCode,
          confirmable ? CoapMessageType.con : CoapMessageType.non,
        ) {
    this.uri = uri;
  }

  /// The request method(code)
  final RequestMethod method;

  @override
  CoapMessageType get type {
    if (super.type == CoapMessageType.con && isMulticast) {
      return CoapMessageType.non;
    }

    return super.type;
  }

  /// Indicates whether this request is a multicast request or not.
  bool get isMulticast => destination?.isMulticast ?? false;

  var _scheme = 'coap';

  String get scheme => _scheme;

  /// Specifies the target resource of a request to a CoAP origin server.
  ///
  /// Composed from the Uri-Host, Uri-Port, Uri-Path, and Uri-Query Options.
  ///
  /// See [RFC 7252, Section 5.10.1] for more information.
  ///
  /// [RFC 7252, Section 5.10.1]: https://www.rfc-editor.org/rfc/rfc7252#section-5.10.1
  Uri get uri {
    final host = getFirstOption<UriHostOption>()?.value ?? destination?.address;
    final path = getOptions<UriPathOption>()
        .map((final option) => option.pathSegment)
        .join();
    final queryParameters = Map.fromEntries(
      getOptions<UriQueryOption>().map((final option) => option.queryParameter),
    );

    final optionPort = getFirstOption<UriPortOption>()?.value;

    final int? port;
    if (!(optionPort == CoapConstants.defaultPort &&
            scheme == CoapConstants.uriScheme) &&
        !(optionPort == CoapConstants.defaultSecurePort &&
            scheme == CoapConstants.secureUriScheme)) {
      port = optionPort;
    } else {
      port = null;
    }

    return Uri(
      scheme: scheme,
      host: host,
      port: port,
      path: path.isNotEmpty ? path : '/',
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );
  }

  @internal
  set uri(final Uri value) {
    final host = value.host;
    var port = value.port;
    final query = value.query;
    final path = value.path;
    if (host.isNotEmpty && InternetAddress.tryParse(host) == null) {
      uriHost = host;
    }
    if (port <= 0) {
      if (value.scheme == CoapConstants.uriScheme) {
        port = CoapConstants.defaultPort;
      } else if (value.scheme == CoapConstants.secureUriScheme) {
        port = CoapConstants.defaultSecurePort;
      }
    }
    uriPort = port;
    if (path.isNotEmpty) {
      uriPath = path;
    }
    if (query.isNotEmpty) {
      uriQuery = value.query;
    }
    // TODO(JKRhb): Check for supported schemes
    if (value.scheme.isNotEmpty) {
      _scheme = value.scheme;
    }
  }

  /// Uri's
  String get uriHost => uri.host;

  @internal
  set uriHost(final String value) {
    setOption(UriHostOption(value));
  }

  /// URI path
  String get uriPath => uri.path;

  /// Sets a number of Uri path options from a string
  set uriPath(final String fullPath) {
    clearUriPath();

    var trimmedPath = fullPath;

    if (fullPath.startsWith('/')) {
      trimmedPath = fullPath.substring(1);
    }

    if (trimmedPath.isEmpty) {
      return;
    }

    trimmedPath.split('/').forEach(addUriPath);
  }

  /// URI paths
  List<UriPathOption> get uriPaths => getOptions<UriPathOption>();

  /// Add a URI path
  void addUriPath(final String path) => addOption(UriPathOption(path));

  /// Remove a URI path
  void removeUriPath(final String path) {
    removeOptionWhere(
      (final element) => element is UriPathOption && element.value == path,
    );
  }

  /// Clear URI paths
  void clearUriPath() => removeOptions<UriPathOption>();

  /// URI query
  String get uriQuery => uri.query;

  /// Set a URI query
  set uriQuery(final String fullQuery) {
    var trimmedQuery = fullQuery;
    if (trimmedQuery.startsWith('?')) {
      trimmedQuery = trimmedQuery.substring(1);
    }
    clearUriQuery();
    trimmedQuery.split('&').forEach(addUriQuery);
  }

  /// URI queries
  List<UriQueryOption> get uriQueries => getOptions<UriQueryOption>();

  /// Add a URI query
  void addUriQuery(final String query) => addOption(UriQueryOption(query));

  /// Remove a URI query
  void removeUriQuery(final String query) {
    removeOptionWhere(
      (final element) => element is UriQueryOption && element.value == query,
    );
  }

  /// Clear URI queries
  void clearUriQuery() => removeOptions<UriQueryOption>();

  /// Uri port
  int get uriPort => uri.port;

  set uriPort(final int value) {
    if (value == 0) {
      removeOptions<UriPortOption>();
    } else {
      addOption(UriPortOption(value));
    }
  }

  Endpoint? _endpoint;

  /// The endpoint for this request
  @internal
  Endpoint? get endpoint => _endpoint;
  @internal
  set endpoint(final Endpoint? endpoint) {
    super.id = endpoint!.nextMessageId;
    _endpoint = endpoint;
  }

  @override
  String toString() => '\n<<< Request Message >>>${super.toString()}';

  /// Construct a GET request.
  factory CoapRequest.newGet(final Uri uri, {final bool confirmable = true}) =>
      CoapRequest(RequestMethod.get, uri, confirmable: confirmable);

  /// Construct a POST request.
  factory CoapRequest.newPost(final Uri uri, {final bool confirmable = true}) =>
      CoapRequest(RequestMethod.post, uri, confirmable: confirmable);

  /// Construct a PUT request.
  factory CoapRequest.newPut(final Uri uri, {final bool confirmable = true}) =>
      CoapRequest(RequestMethod.put, uri, confirmable: confirmable);

  /// Construct a DELETE request.
  factory CoapRequest.newDelete(
    final Uri uri, {
    final bool confirmable = true,
  }) =>
      CoapRequest(RequestMethod.delete, uri, confirmable: confirmable);

  /// Construct a FETCH request.
  factory CoapRequest.newFetch(
    final Uri uri, {
    final bool confirmable = true,
  }) =>
      CoapRequest(RequestMethod.fetch, uri, confirmable: confirmable);

  /// Construct a PATCH request.
  factory CoapRequest.newPatch(
    final Uri uri, {
    final bool confirmable = true,
  }) =>
      CoapRequest(RequestMethod.patch, uri, confirmable: confirmable);

  /// Construct a iPATCH request.
  factory CoapRequest.newIPatch(
    final Uri uri, {
    final bool confirmable = true,
  }) =>
      CoapRequest(RequestMethod.ipatch, uri, confirmable: confirmable);

  CoapRequest.fromParsed(
    this.method, {
    required final CoapMessageType type,
    required final int id,
    required final Uint8Buffer token,
    required final List<Option<Object?>> options,
    required final Uint8Buffer? payload,
    required final bool hasUnknownCriticalOption,
    required final bool hasFormatError,
  }) : super.fromParsed(
          method.coapCode,
          type,
          id: id,
          token: token,
          options: options,
          hasUnknownCriticalOption: hasUnknownCriticalOption,
          hasFormatError: hasFormatError,
          payload: payload,
        );
}
