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
import 'net/endpoint.dart';
import 'option/option.dart';
import 'option/uri_converters.dart';

/// This class describes the functionality of a CoAP Request as
/// a subclass of a CoAP Message. It provides:
/// 1. operations to answer a request by a response using respond()
/// 2. different ways to handle incoming responses:
/// receiveResponse() or Response event.
class CoapRequest extends CoapMessage {
  /// Initializes a request message.
  /// Defaults to confirmable
  CoapRequest(this.uri, this.method, {final bool confirmable = true})
      : super(
          method.coapCode,
          confirmable ? CoapMessageType.con : CoapMessageType.non,
        );

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

  /// Specifies the target resource of a request to a CoAP origin server.
  ///
  /// Composed from the Uri-Host, Uri-Port, Uri-Path, and Uri-Query Options.
  ///
  /// See [RFC 7252, Section 5.10.1] for more information.
  ///
  /// [RFC 7252, Section 5.10.1]: https://www.rfc-editor.org/rfc/rfc7252#section-5.10.1
  final Uri uri;

  @override
  List<Option<Object?>> getAllOptions() =>
      uriToOptions(uri, destination)..addAll(super.getAllOptions());

  Endpoint? _endpoint;

  /// The endpoint for this request
  @internal
  Endpoint? get endpoint => _endpoint;
  @internal
  set endpoint(final Endpoint? endpoint) {
    super.id = endpoint!.nextMessageId;
    super.destination = endpoint.destination;
    _endpoint = endpoint;
  }

  @override
  String toString() => '\n<<< Request Message >>>${super.toString()}';

  /// Construct a GET request.
  factory CoapRequest.newGet(final Uri uri, {final bool confirmable = true}) =>
      CoapRequest(uri, RequestMethod.get, confirmable: confirmable);

  /// Construct a POST request.
  factory CoapRequest.newPost(final Uri uri, {final bool confirmable = true}) =>
      CoapRequest(uri, RequestMethod.post, confirmable: confirmable);

  /// Construct a PUT request.
  factory CoapRequest.newPut(final Uri uri, {final bool confirmable = true}) =>
      CoapRequest(uri, RequestMethod.put, confirmable: confirmable);

  /// Construct a DELETE request.
  factory CoapRequest.newDelete(
    final Uri uri, {
    final bool confirmable = true,
  }) =>
      CoapRequest(uri, RequestMethod.delete, confirmable: confirmable);

  /// Construct a FETCH request.
  factory CoapRequest.newFetch(
    final Uri uri, {
    final bool confirmable = true,
  }) =>
      CoapRequest(uri, RequestMethod.fetch, confirmable: confirmable);

  /// Construct a PATCH request.
  factory CoapRequest.newPatch(
    final Uri uri, {
    final bool confirmable = true,
  }) =>
      CoapRequest(uri, RequestMethod.patch, confirmable: confirmable);

  /// Construct a iPATCH request.
  factory CoapRequest.newIPatch(
    final Uri uri, {
    final bool confirmable = true,
  }) =>
      CoapRequest(uri, RequestMethod.ipatch, confirmable: confirmable);

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
}
