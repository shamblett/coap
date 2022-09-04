/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

import 'dart:io';

import 'package:meta/meta.dart';

import 'coap_code.dart';
import 'coap_constants.dart';
import 'coap_message.dart';
import 'coap_message_type.dart';
import 'net/coap_iendpoint.dart';

/// This class describes the functionality of a CoAP Request as
/// a subclass of a CoAP Message. It provides:
/// 1. operations to answer a request by a response using respond()
/// 2. different ways to handle incoming responses:
/// receiveResponse() or Response event.
class CoapRequest extends CoapMessage {
  /// Initializes a request message.
  /// Defaults to confirmable
  CoapRequest(final CoapCode code, {final bool confirmable = true})
      : super(
          code,
          confirmable ? CoapMessageType.con : CoapMessageType.non,
        ) {
    if (!code.isRequest && !code.isEmpty) {
      throw ArgumentError('Expected CoAP method code, got $code');
    }
  }

  /// The request method(code)
  CoapCode get method => code;

  @override
  CoapMessageType? get type {
    if (super.type == CoapMessageType.con && isMulticast) {
      return CoapMessageType.non;
    }

    return super.type;
  }

  /// Indicates whether this request is a multicast request or not.
  bool get isMulticast => destination?.isMulticast ?? false;

  Uri? _uri;

  /// The URI of this CoAP message.
  Uri get uri => _uri ??= Uri(
        scheme: CoapConstants.uriScheme,
        host: uriHost ?? 'localhost',
        port: uriPort,
        path: uriPath,
        query: uriQuery,
      );

  @internal
  set uri(final Uri value) {
    final host = value.host;
    var port = value.port;
    if (host.isNotEmpty &&
        InternetAddress.tryParse(host) == null &&
        host != 'localhost') {
      uriHost = host;
    }
    if (port <= 0) {
      if (value.scheme.isNotEmpty || value.scheme == CoapConstants.uriScheme) {
        port = CoapConstants.defaultPort;
      } else if (value.scheme == CoapConstants.secureUriScheme) {
        port = CoapConstants.defaultSecurePort;
      }
    }
    if (uriPort != port) {
      if (port != CoapConstants.defaultPort) {
        uriPort = port;
      } else {
        uriPort = CoapConstants.defaultPort;
      }
    }
    resolveHost = host;
    _uri = value;
  }

  CoapIEndPoint? _endpoint;

  /// The endpoint for this request
  @internal
  CoapIEndPoint? get endpoint => _endpoint;
  @internal
  set endpoint(final CoapIEndPoint? endpoint) {
    super.id = endpoint!.nextMessageId;
    super.destination = endpoint.destination;
    _endpoint = endpoint;
  }

  @override
  String toString() => '\n<<< Request Message >>>${super.toString()}';

  /// Construct a GET request.
  factory CoapRequest.newGet({final bool confirmable = true}) =>
      CoapRequest(CoapCode.get, confirmable: confirmable);

  /// Construct a POST request.
  factory CoapRequest.newPost({final bool confirmable = true}) =>
      CoapRequest(CoapCode.post, confirmable: confirmable);

  /// Construct a PUT request.
  factory CoapRequest.newPut({final bool confirmable = true}) =>
      CoapRequest(CoapCode.put, confirmable: confirmable);

  /// Construct a DELETE request.
  factory CoapRequest.newDelete({final bool confirmable = true}) =>
      CoapRequest(CoapCode.delete, confirmable: confirmable);

  /// Construct a FETCH request.
  factory CoapRequest.newFetch({final bool confirmable = true}) =>
      CoapRequest(CoapCode.fetch, confirmable: confirmable);

  /// Construct a PATCH request.
  factory CoapRequest.newPatch({final bool confirmable = true}) =>
      CoapRequest(CoapCode.patch, confirmable: confirmable);

  /// Construct a iPATCH request.
  factory CoapRequest.newIPatch({final bool confirmable = true}) =>
      CoapRequest(CoapCode.ipatch, confirmable: confirmable);
}
