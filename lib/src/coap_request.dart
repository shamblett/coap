/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

import 'package:meta/meta.dart';
import 'package:typed_data/typed_buffers.dart';

import 'coap_code.dart';
import 'coap_media_type.dart';
import 'coap_message.dart';
import 'coap_message_type.dart';
import 'net/endpoint.dart';
import 'option/option.dart';
import 'option/uri_converters.dart';

/// This class describes the functionality of a CoAP Request as
/// a subclass of a CoAP Message. It provides:
/// 1. operations to answer a request by a response using respond()
/// 2. different ways to handle incoming responses:
/// receiveResponse() or Response event.
class CoapRequest extends CoapMessage {
  /// Specifies the target resource of a request to a CoAP origin server.
  ///
  /// Composed from the Uri-Host, Uri-Port, Uri-Path, and Uri-Query Options.
  ///
  /// See [RFC 7252, Section 5.10.1] for more information.
  ///
  /// [RFC 7252, Section 5.10.1]: https://www.rfc-editor.org/rfc/rfc7252#section-5.10.1
  Uri uri;

  /// The request method(code)
  final RequestMethod method;

  Endpoint? _endpoint;

  @override
  CoapMessageType get type {
    if (super.type == CoapMessageType.con && isMulticast) {
      return CoapMessageType.non;
    }

    return super.type;
  }

  /// The endpoint for this request
  @internal
  Endpoint? get endpoint => _endpoint;

  /// Indicates whether this request is a multicast request or not.
  bool get isMulticast => destination?.isMulticast ?? false;

  @internal
  set endpoint(final Endpoint? endpoint) {
    super.id = endpoint!.nextMessageId;
    super.destination = endpoint.destination;
    _endpoint = endpoint;
  }

  /// Initializes a request message.
  /// Defaults to confirmable
  CoapRequest(
    this.uri,
    this.method, {
    final bool confirmable = true,
    super.payload,
    final CoapMediaType? accept,
    super.contentFormat,
  }) : super(
         method.coapCode,
         confirmable ? CoapMessageType.con : CoapMessageType.non,
       ) {
    super.accept = accept;
  }

  /// Construct a GET request.
  factory CoapRequest.get(
    final Uri uri, {
    final bool confirmable = true,
    final Iterable<int>? payload,
    final CoapMediaType? accept,
  }) => CoapRequest(
    uri,
    RequestMethod.get,
    confirmable: confirmable,
    payload: payload,
    accept: accept,
  );

  /// Construct a POST request.
  factory CoapRequest.post(
    final Uri uri, {
    final bool confirmable = true,
    final Iterable<int>? payload,
    final CoapMediaType? contentFormat,
    final CoapMediaType? accept,
  }) => CoapRequest(
    uri,
    RequestMethod.post,
    confirmable: confirmable,
    payload: payload,
    contentFormat: contentFormat,
    accept: accept,
  );

  /// Construct a PUT request.
  factory CoapRequest.put(
    final Uri uri, {
    final bool confirmable = true,
    final Iterable<int>? payload,
    final CoapMediaType? contentFormat,
    final CoapMediaType? accept,
  }) => CoapRequest(
    uri,
    RequestMethod.put,
    confirmable: confirmable,
    payload: payload,
    contentFormat: contentFormat,
    accept: accept,
  );

  /// Construct a DELETE request.
  factory CoapRequest.delete(
    final Uri uri, {
    final bool confirmable = true,
    final Iterable<int>? payload,
    final CoapMediaType? accept,
  }) => CoapRequest(
    uri,
    RequestMethod.delete,
    confirmable: confirmable,
    payload: payload,
    accept: accept,
  );

  /// Construct a FETCH request.
  factory CoapRequest.fetch(
    final Uri uri, {
    final bool confirmable = true,
    final Iterable<int>? payload,
    final CoapMediaType? contentFormat,
    final CoapMediaType? accept,
  }) => CoapRequest(
    uri,
    RequestMethod.fetch,
    confirmable: confirmable,
    payload: payload,
    contentFormat: contentFormat,
    accept: accept,
  );

  /// Construct a PATCH request.
  factory CoapRequest.patch(
    final Uri uri, {
    final bool confirmable = true,
    final Iterable<int>? payload,
    final CoapMediaType? contentFormat,
    final CoapMediaType? accept,
  }) => CoapRequest(
    uri,
    RequestMethod.patch,
    confirmable: confirmable,
    payload: payload,
    contentFormat: contentFormat,
    accept: accept,
  );

  /// Construct a iPATCH request.
  factory CoapRequest.iPatch(
    final Uri uri, {
    final bool confirmable = true,
    final Iterable<int>? payload,
    final CoapMediaType? contentFormat,
    final CoapMediaType? accept,
  }) => CoapRequest(
    uri,
    RequestMethod.ipatch,
    confirmable: confirmable,
    payload: payload,
    contentFormat: contentFormat,
    accept: accept,
  );

  CoapRequest.fromParsed(
    this.uri,
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

  @override
  List<Option<Object?>> getAllOptions() =>
      uriToOptions(uri, destination)..addAll(super.getAllOptions());

  @override
  String toString() => '\n<<< Request Message >>>${super.toString()}';
}
