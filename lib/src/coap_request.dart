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
import 'network/credentials/ecdsa_keys.dart';
import 'network/credentials/psk_credentials.dart';

/// This class describes the functionality of a CoAP Request as
/// a subclass of a CoAP Message. It provides:
/// 1. operations to answer a request by a response using respond()
/// 2. different ways to handle incoming responses:
/// receiveResponse() or Response event.
class CoapRequest extends CoapMessage {
  /// Initializes a request message.
  /// Defaults to confirmable
  CoapRequest(
    Uri uri,
    int code, {
    bool confirmable = true,
    this.ecdsaKeys,
    this.pskCredentialsCallback,
  }) : super(
            code: code,
            type: confirmable ? CoapMessageType.con : CoapMessageType.non) {
    this.uri = uri;
  }

  /// The request method(code)
  int get method => super.code;

  /// Raw Public Keys for CoAPS with tinyDtls.
  final EcdsaKeys? ecdsaKeys;

  /// Callback for providing [PskCredentials] (combination of a Pre-shared Key
  /// and an Identity) for DTLS, optionally based on an Identity Hint.
  final PskCredentialsCallback? pskCredentialsCallback;

  @override
  int get type {
    if (super.type == CoapMessageType.con && isMulticast) {
      return CoapMessageType.non;
    }

    return super.type;
  }

  /// Indicates whether this request is a multicast request or not.
  bool get isMulticast => destination?.address.isMulticast ?? false;

  Uri? _uri;

  /// The URI of this CoAP message.
  Uri get uri => _uri ??= Uri(
      scheme: CoapConstants.uriScheme,
      host: uriHost ?? 'localhost',
      port: uriPort,
      path: uriPath,
      query: uriQuery);

  @protected
  set uri(Uri value) {
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
    uriPath = value.path;
    uriQuery = value.query;
    resolveHost = host;
    _uri = value;
  }

  CoapIEndPoint? _endpoint;

  /// The endpoint for this request
  @protected
  CoapIEndPoint? get endpoint => _endpoint;
  @protected
  set endpoint(CoapIEndPoint? endpoint) {
    super.id = endpoint!.nextMessageId;
    super.destination = endpoint.destination;
    _endpoint = endpoint;
  }

  @override
  String toString() => '\n<<< Request Message >>>${super.toString()}';

  /// Construct a GET request.
  static CoapRequest newGet(
    Uri uri, {
    EcdsaKeys? ecdsaKeys,
    PskCredentialsCallback? pskCredentialsCallback,
  }) =>
      CoapRequest(uri, CoapCode.methodGET,
          ecdsaKeys: ecdsaKeys, pskCredentialsCallback: pskCredentialsCallback);

  /// Construct a POST request.
  static CoapRequest newPost(
    Uri uri, {
    EcdsaKeys? ecdsaKeys,
    PskCredentialsCallback? pskCredentialsCallback,
  }) =>
      CoapRequest(uri, CoapCode.methodPOST,
          ecdsaKeys: ecdsaKeys, pskCredentialsCallback: pskCredentialsCallback);

  /// Construct a PUT request.
  static CoapRequest newPut(
    Uri uri, {
    EcdsaKeys? ecdsaKeys,
    PskCredentialsCallback? pskCredentialsCallback,
  }) =>
      CoapRequest(uri, CoapCode.methodPUT,
          ecdsaKeys: ecdsaKeys, pskCredentialsCallback: pskCredentialsCallback);

  /// Construct a DELETE request.
  static CoapRequest newDelete(
    Uri uri, {
    EcdsaKeys? ecdsaKeys,
    PskCredentialsCallback? pskCredentialsCallback,
  }) =>
      CoapRequest(uri, CoapCode.methodDELETE,
          ecdsaKeys: ecdsaKeys, pskCredentialsCallback: pskCredentialsCallback);
}
