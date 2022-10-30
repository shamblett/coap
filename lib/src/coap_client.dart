/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 05/06/2018
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:synchronized/synchronized.dart';
import 'package:typed_data/typed_data.dart';

import '../config/coap_config_default.dart';
import 'coap_code.dart';
import 'coap_config.dart';
import 'coap_constants.dart';
import 'coap_empty_message.dart';
import 'coap_media_type.dart';
import 'coap_message.dart';
import 'coap_message_type.dart';
import 'coap_observe_client_relation.dart';
import 'coap_request.dart';
import 'coap_response.dart';
import 'event/coap_event_bus.dart';
import 'exceptions/coap_request_exception.dart';
import 'link-format/coap_link_format.dart';
import 'link-format/coap_web_link.dart';
import 'net/endpoint.dart';
import 'network/coap_inetwork.dart';
import 'network/credentials/ecdsa_keys.dart';
import 'network/credentials/psk_credentials.dart';
import 'option/coap_block_option.dart';
import 'option/empty_option.dart';
import 'option/integer_option.dart';
import 'option/option.dart';

/// The matching scheme to use for supplied ETags on PUT
// FIXME: The name MatchETags might be a bit misleading, c.f. https://datatracker.ietf.org/doc/html/rfc7252#section-5.10.8.2
enum MatchEtags {
  /// When the ETag matches
  onMatch,

  /// When none of the ETag matches
  onNoneMatch,
}

/// Response event handler for multicast responses
class CoapMulticastResponseHandler {
  final void Function(CoapResponse)? onData;
  final Function? onError;
  final void Function()? onDone;
  final bool? cancelOnError;

  CoapMulticastResponseHandler(
    this.onData, {
    this.onError,
    this.onDone,
    this.cancelOnError,
  });
}

/// Provides convenient methods for accessing CoAP resources.
/// This class provides a fairly high level interface for the majority of
/// simple CoAP requests but because of this is fairly coarsely grained.
/// Much finer control of a request can be achieved by direct construction
/// and manipulation of a CoapRequest itself, however this is more involved,
/// for most cases the API in this class should suffice.
///
/// Note that currently a self constructed resource must be prepared
/// by the prepare method in this class BEFORE calling any send
/// methods on the resource.
///
/// In most cases a resource can be created outside of the client with
/// the relevant parameters then set in the client.
class CoapClient {
  /// Instantiates.
  /// A supplied request is optional depending on the API call being used.
  /// If it is specified it will be prepared and used.
  /// Note that the host name part of the URI can be a name or an IP address,
  /// in which case it is not resolved.
  ///
  /// You can define a custom [config] for the creation of a [CoapClient].
  /// If no [config] is provided, then an instance of the [CoapConfigDefault]
  /// class will be used instead.
  CoapClient(
    this.uri, {
    this.addressType = InternetAddressType.any,
    this.bindAddress,
    final EcdsaKeys? ecdsaKeys,
    final PskCredentialsCallback? pskCredentialsCallback,
    final DefaultCoapConfig? config,
  })  : _config = config ?? CoapConfigDefault(),
        _ecdsaKeys = ecdsaKeys,
        _pskCredentialsCallback = pskCredentialsCallback {
    _eventBus = CoapEventBus(namespace: hashCode.toString());
  }

  /// Address type used for DNS lookups.
  final InternetAddressType addressType;

  /// The client's local socket bind address, if set explicitly
  /// IPv4 default is 0.0.0.0, IPv6 default is 0:0:0:0:0:0:0:0
  final InternetAddress? bindAddress;

  /// The client endpoint URI
  final Uri uri;

  late final CoapEventBus _eventBus;

  /// The internal request/response event stream
  CoapEventBus get events => _eventBus;

  final DefaultCoapConfig _config;
  Endpoint? _endpoint;
  final _lock = Lock();

  /// Raw Public Keys for CoAPS with tinyDtls.
  final EcdsaKeys? _ecdsaKeys;

  /// Callback for providing [PskCredentials] (combination of a Pre-shared Key
  /// and an Identity) for DTLS, optionally based on an Identity Hint.
  final PskCredentialsCallback? _pskCredentialsCallback;

  /// Performs a CoAP ping.
  Future<bool> ping() async {
    final request = CoapRequest(RequestMethod.empty)
      ..token = CoapConstants.emptyToken;
    await _prepare(request);
    _endpoint!.sendEpRequest(request);
    await _waitForReject(request);
    return request.isRejected;
  }

  /// Sends a GET request.
  Future<CoapResponse> get(
    final String path, {
    final CoapMediaType? accept,
    final bool confirmable = true,
    final List<Option<Object?>>? options,
    final bool earlyBlock2Negotiation = false,
    final int maxRetransmit = 0,
    final CoapMulticastResponseHandler? onMulticastResponse,
  }) {
    final request = CoapRequest.newGet(confirmable: confirmable);
    _build(
      request,
      path,
      accept,
      options,
      earlyBlock2Negotiation,
      maxRetransmit,
    );
    return send(request, onMulticastResponse: onMulticastResponse);
  }

  /// Sends a POST request.
  Future<CoapResponse> post(
    final String path, {
    required final String payload,
    final CoapMediaType? format,
    final CoapMediaType? accept,
    final bool confirmable = true,
    final List<Option<Object?>>? options,
    final bool earlyBlock2Negotiation = false,
    final int maxRetransmit = 0,
    final CoapMulticastResponseHandler? onMulticastResponse,
  }) {
    final request = CoapRequest.newPost(confirmable: confirmable)
      ..setPayloadMedia(payload, format);
    _build(
      request,
      path,
      accept,
      options,
      earlyBlock2Negotiation,
      maxRetransmit,
    );
    return send(request, onMulticastResponse: onMulticastResponse);
  }

  /// Sends a POST request with the specified byte payload.
  Future<CoapResponse> postBytes(
    final String path, {
    required final Uint8Buffer payload,
    final CoapMediaType? format,
    final CoapMediaType? accept,
    final bool confirmable = true,
    final List<Option<Object?>>? options,
    final bool earlyBlock2Negotiation = false,
    final int maxRetransmit = 0,
    final CoapMulticastResponseHandler? onMulticastResponse,
  }) {
    final request = CoapRequest.newPost(confirmable: confirmable)
      ..setPayloadMediaRaw(payload, format);
    _build(
      request,
      path,
      accept,
      options,
      earlyBlock2Negotiation,
      maxRetransmit,
    );
    return send(request, onMulticastResponse: onMulticastResponse);
  }

  /// Sends a PUT request.
  Future<CoapResponse> put(
    final String path, {
    required final String payload,
    final CoapMediaType? format,
    final CoapMediaType? accept,
    final bool confirmable = true,
    final List<Uint8Buffer>? etags,
    final MatchEtags matchEtags = MatchEtags.onMatch,
    final List<Option<Object?>>? options,
    final bool earlyBlock2Negotiation = false,
    final int maxRetransmit = 0,
    final CoapMulticastResponseHandler? onMulticastResponse,
  }) {
    final request = CoapRequest.newPut(confirmable: confirmable)
      ..setPayloadMedia(payload, format);
    _build(
      request,
      path,
      accept,
      options,
      earlyBlock2Negotiation,
      maxRetransmit,
      etags: etags,
      matchEtags: matchEtags,
    );
    return send(request, onMulticastResponse: onMulticastResponse);
  }

  /// Sends a PUT request with the specified byte payload.
  Future<CoapResponse> putBytes(
    final String path, {
    required final Uint8Buffer payload,
    final CoapMediaType? format,
    final MatchEtags matchEtags = MatchEtags.onMatch,
    final List<Uint8Buffer>? etags,
    final CoapMediaType? accept,
    final bool confirmable = true,
    final List<Option<Object?>>? options,
    final bool earlyBlock2Negotiation = false,
    final int maxRetransmit = 0,
    final CoapMulticastResponseHandler? onMulticastResponse,
  }) {
    final request = CoapRequest.newPut(confirmable: confirmable)
      ..setPayloadMediaRaw(payload, format);
    _build(
      request,
      path,
      accept,
      options,
      earlyBlock2Negotiation,
      maxRetransmit,
      etags: etags,
      matchEtags: matchEtags,
    );
    return send(request, onMulticastResponse: onMulticastResponse);
  }

  /// Sends a DELETE request
  Future<CoapResponse> delete(
    final String path, {
    final CoapMediaType? accept,
    final bool confirmable = true,
    final List<Option<Object?>>? options,
    final bool earlyBlock2Negotiation = false,
    final int maxRetransmit = 0,
    final CoapMulticastResponseHandler? onMulticastResponse,
  }) {
    final request = CoapRequest.newDelete(confirmable: confirmable);
    _build(
      request,
      path,
      accept,
      options,
      earlyBlock2Negotiation,
      maxRetransmit,
    );
    return send(request, onMulticastResponse: onMulticastResponse);
  }

  /// Sends a FETCH request.
  ///
  /// See [RFC 8132, section 2].
  ///
  /// [RFC 8132, section 2]: https://www.rfc-editor.org/rfc/rfc8132.html#section-2
  Future<CoapResponse> fetch(
    final String path, {
    final CoapMediaType? accept,
    final bool confirmable = true,
    final List<Option<Object?>>? options,
    final bool earlyBlock2Negotiation = false,
    final int maxRetransmit = 0,
    final CoapMulticastResponseHandler? onMulticastResponse,
  }) {
    final request = CoapRequest.newFetch(confirmable: confirmable);
    _build(
      request,
      path,
      accept,
      options,
      earlyBlock2Negotiation,
      maxRetransmit,
    );
    return send(request, onMulticastResponse: onMulticastResponse);
  }

  /// Sends a PATCH request.
  ///
  /// See [RFC 8132, section 3].
  ///
  /// [RFC 8132, section 3]: https://www.rfc-editor.org/rfc/rfc8132.html#section-3
  Future<CoapResponse> patch(
    final String path, {
    required final String payload,
    final CoapMediaType? format,
    final CoapMediaType? accept,
    final bool confirmable = true,
    final List<Uint8Buffer>? etags,
    final MatchEtags matchEtags = MatchEtags.onMatch,
    final List<Option<Object?>>? options,
    final bool earlyBlock2Negotiation = false,
    final int maxRetransmit = 0,
    final CoapMulticastResponseHandler? onMulticastResponse,
  }) {
    final request = CoapRequest.newPatch(confirmable: confirmable)
      ..setPayloadMedia(payload, format);
    _build(
      request,
      path,
      accept,
      options,
      earlyBlock2Negotiation,
      maxRetransmit,
      etags: etags,
      matchEtags: matchEtags,
    );
    return send(request, onMulticastResponse: onMulticastResponse);
  }

  /// Sends a PATCH request with the specified byte payload.
  ///
  /// See [RFC 8132, section 3].
  ///
  /// [RFC 8132, section 3]: https://www.rfc-editor.org/rfc/rfc8132.html#section-3
  Future<CoapResponse> patchBytes(
    final String path, {
    required final Uint8Buffer payload,
    final CoapMediaType? format,
    final MatchEtags matchEtags = MatchEtags.onMatch,
    final List<Uint8Buffer>? etags,
    final CoapMediaType? accept,
    final bool confirmable = true,
    final List<Option<Object?>>? options,
    final bool earlyBlock2Negotiation = false,
    final int maxRetransmit = 0,
    final CoapMulticastResponseHandler? onMulticastResponse,
  }) {
    final request = CoapRequest.newPatch(confirmable: confirmable)
      ..setPayloadMediaRaw(payload, format);
    _build(
      request,
      path,
      accept,
      options,
      earlyBlock2Negotiation,
      maxRetransmit,
      etags: etags,
      matchEtags: matchEtags,
    );
    return send(request, onMulticastResponse: onMulticastResponse);
  }

  /// Sends an iPATCH request.
  ///
  /// See [RFC 8132, section 3].
  ///
  /// [RFC 8132, section 3]: https://www.rfc-editor.org/rfc/rfc8132.html#section-3
  Future<CoapResponse> iPatch(
    final String path, {
    required final String payload,
    final CoapMediaType? format,
    final CoapMediaType? accept,
    final bool confirmable = true,
    final List<Uint8Buffer>? etags,
    final MatchEtags matchEtags = MatchEtags.onMatch,
    final List<Option<Object?>>? options,
    final bool earlyBlock2Negotiation = false,
    final int maxRetransmit = 0,
    final CoapMulticastResponseHandler? onMulticastResponse,
  }) {
    final request = CoapRequest.newIPatch(confirmable: confirmable)
      ..setPayloadMedia(payload, format);
    _build(
      request,
      path,
      accept,
      options,
      earlyBlock2Negotiation,
      maxRetransmit,
      etags: etags,
      matchEtags: matchEtags,
    );
    return send(request, onMulticastResponse: onMulticastResponse);
  }

  /// Sends a iPATCH request with the specified byte payload.
  ///
  /// See [RFC 8132, section 3].
  ///
  /// [RFC 8132, section 3]: https://www.rfc-editor.org/rfc/rfc8132.html#section-3
  Future<CoapResponse> iPatchBytes(
    final String path, {
    required final Uint8Buffer payload,
    final CoapMediaType? format,
    final MatchEtags matchEtags = MatchEtags.onMatch,
    final List<Uint8Buffer>? etags,
    final CoapMediaType? accept,
    final bool confirmable = true,
    final List<Option<Object?>>? options,
    final bool earlyBlock2Negotiation = false,
    final int maxRetransmit = 0,
    final CoapMulticastResponseHandler? onMulticastResponse,
  }) {
    final request = CoapRequest.newIPatch(confirmable: confirmable)
      ..setPayloadMediaRaw(payload, format);
    _build(
      request,
      path,
      accept,
      options,
      earlyBlock2Negotiation,
      maxRetransmit,
      etags: etags,
      matchEtags: matchEtags,
    );
    return send(request, onMulticastResponse: onMulticastResponse);
  }

  /// Observe
  Future<CoapObserveClientRelation> observe(
    final CoapRequest request, {
    final int maxRetransmit = 0,
  }) async {
    request
      ..observe = ObserveRegistration.register.value
      ..maxRetransmit = maxRetransmit;
    final responseStream = _sendWithStreamResponse(request).asBroadcastStream();
    final relation = CoapObserveClientRelation(request, responseStream);
    unawaited(
      () async {
        final resp = await _waitForResponse(request, responseStream);
        if (!resp.hasOption<ObserveOption>()) {
          relation.isCancelled = true;
        }
      }(),
    );
    return relation;
  }

  /// Discovers remote resources.
  Future<Iterable<CoapWebLink>?> discover({
    final String query = '',
  }) async {
    final discover = CoapRequest.newGet()
      ..uriPath = CoapConstants.defaultWellKnownURI;
    if (query.isNotEmpty) {
      discover.uriQuery = query;
    }
    final links = await send(discover);
    if (links.contentFormat != CoapMediaType.applicationLinkFormat) {
      return <CoapWebLink>[CoapWebLink('')];
    } else {
      return CoapLinkFormat.parse(links.payloadString);
    }
  }

  /// Send
  Future<CoapResponse> send(
    final CoapRequest request, {
    final CoapMulticastResponseHandler? onMulticastResponse,
  }) async {
    final responseStream = _sendWithStreamResponse(request).asBroadcastStream();
    if (request.isMulticast) {
      if (onMulticastResponse == null) {
        throw ArgumentError('Missing onMulticastResponse argument');
      }
      responseStream.listen(
        onMulticastResponse.onData,
        onError: onMulticastResponse.onError,
        onDone: onMulticastResponse.onDone,
        cancelOnError: onMulticastResponse.cancelOnError,
      );
    }
    return _waitForResponse(request, responseStream);
  }

  Stream<CoapResponse> _sendWithStreamResponse(
    final CoapRequest request,
  ) async* {
    await _prepare(request);

    final stream = _eventBus
        .on<CoapCompletionEvent>()
        .transform<CoapResponse>(_filterEventStream(request))
        .where((final response) => _matchResponse(response, request))
        .takeWhile((final _) => request.isActive);

    _endpoint!.sendEpRequest(request);

    yield* stream;
  }

  /// Sends a [request] and returns a [Stream] of [CoapResponse]s.
  ///
  /// This method is especially useful for multicast scenarios, allowing the
  /// caller to asynchronously iterate over incoming responses. However, you
  /// can also use it for obtaining the response to a unicast requests as a
  ///[Stream].
  Stream<CoapResponse> sendMulticast(final CoapRequest request) async* {
    yield* _sendWithStreamResponse(request);
  }

  /// Cancel ongoing observable request
  Future<void> cancelObserveProactive(
    final CoapObserveClientRelation relation,
  ) async {
    final cancel = relation.newCancel();
    await send(cancel);
    relation.isCancelled = true;
  }

  /// Cancel after the fact
  void cancelObserveReactive(final CoapObserveClientRelation relation) {
    relation.isCancelled = true;
  }

  /// Cancels a request
  void cancel(final CoapRequest request) {
    request.isCancelled = true;
    final response = CoapEmptyMessage(CoapMessageType.rst)
      ..id = request.id
      ..token = request.token;
    _eventBus.fire(CoapCancelledEvent(response));
  }

  /// Cancel all ongoing requests
  void close() {
    _endpoint?.stop();
  }

  void _build(
    final CoapRequest request,
    final String path,
    final CoapMediaType? accept,
    final List<Option<Object?>>? options,
    final bool earlyBlock2Negotiation,
    final int maxRetransmit, {
    final MatchEtags matchEtags = MatchEtags.onMatch,
    final List<Uint8Buffer>? etags,
  }) {
    request
      ..uriPath = path
      ..accept = accept
      ..maxRetransmit = maxRetransmit;
    if (options != null) {
      request.addOptions(options);
    }
    if (etags != null) {
      switch (matchEtags) {
        case MatchEtags.onMatch:
          etags.forEach(request.addIfMatchOpaque);
          break;
        case MatchEtags.onNoneMatch:
          request.addOption(IfNoneMatchOption());
      }
    }
    if (earlyBlock2Negotiation) {
      request.setBlock2(
        BlockSize.fromDecodedValue(_config.preferredBlockSize),
        0,
        m: false,
      );
    }
  }

  Future<void> _prepare(final CoapRequest request) async {
    request
      ..uri = uri
      ..timestamp = DateTime.now()
      ..eventBus = _eventBus;

    await _lock.synchronized(() async {
      // Set endpoint if missing
      if (_endpoint == null) {
        final destination = await _lookupHost(uri.host, addressType);
        final socket = CoapINetwork.fromUri(
          uri,
          address: destination,
          bindAddress: bindAddress,
          config: _config,
          namespace: _eventBus.namespace,
          pskCredentialsCallback: _pskCredentialsCallback,
          ecdsaKeys: _ecdsaKeys,
        );
        await socket.init();
        _endpoint = Endpoint(socket, _config, namespace: _eventBus.namespace);
        _endpoint!.start();
      }
    });

    request.endpoint = _endpoint;
  }

  Future<InternetAddress> _lookupHost(
    final String host,
    final InternetAddressType addressType,
  ) async {
    final parsedAddress = InternetAddress.tryParse(host);
    if (parsedAddress != null) {
      return parsedAddress;
    }

    final addresses = await InternetAddress.lookup(host, type: addressType);
    if (addresses.isNotEmpty) {
      return addresses[0];
    }

    throw SocketException("Failed host lookup: '$host'");
  }

  /// Wait for a response.
  /// Returns the response, or null if timeout occured.
  static Future<CoapResponse> _waitForResponse(
    final CoapRequest request,
    final Stream<CoapResponse> responseStream,
  ) {
    final completer = Completer<CoapResponse>();
    responseStream.take(1).listen(
      (final response) {
        response.timestamp = DateTime.now();
        completer.complete(response);
      },
      onError: completer.completeError,
    );
    return completer.future;
  }

  /// Wait for a reject.
  /// Returns the rejected message, or null if timeout occured.
  Future<CoapMessage?> _waitForReject(final CoapRequest req) {
    final completer = Completer<CoapMessage?>();
    _eventBus
        .on<CoapRejectedEvent>()
        .where((final e) => e.msg.id == req.id)
        .take(1)
        .listen((final e) {
      if (!req.isActive) {
        completer.complete(null);
      } else {
        e.msg.timestamp = DateTime.now();
        completer.complete(e.msg);
      }
    });
    return completer.future;
  }
}

bool _matchResponse(final CoapResponse response, final CoapRequest request) =>
    response.token!.equals(request.token!) ||
    (response.multicastToken?.equals(request.token!) ?? false);

StreamTransformer<CoapCompletionEvent, CoapResponse> _filterEventStream(
  final CoapRequest request,
) =>
    StreamTransformer<CoapCompletionEvent, CoapResponse>(
        (final input, final cancelOnError) {
      final controller = StreamController<CoapResponse>();

      controller.onListen = () {
        final subscription = input.listen(
          (final event) async {
            if (event is CoapRespondEvent) {
              controller.add(event.resp);
            } else if (event is CoapTimedOutEvent) {
              controller.addError(
                CoapRequestTimeoutException(request.maxRetransmit),
              );
            }
          },
          onDone: controller.close,
          onError: controller.addError,
          cancelOnError: cancelOnError,
        );
        controller
          ..onPause = subscription.pause
          ..onResume = subscription.resume
          ..onCancel = subscription.cancel;
      };

      return controller.stream.listen(null);
    });
