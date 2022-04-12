/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 05/06/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Request fail reason
enum FailReason {
  /// The request has been rejected.
  rejected,

  /// The request has been timed out.
  timedOut
}

/// The matching scheme to use for supplied ETags on PUT
enum MatchEtags {
  /// When the ETag matches
  onMatch,

  /// When none of the ETag matches
  onNoneMatch,
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
  CoapClient(this.uri, this._config,
      {this.addressType = InternetAddressType.IPv4, Duration? timeout}) {
    this.timeout = timeout ?? Duration(milliseconds: _config.defaultTimeout);
    _namespace = hashCode.toString();
  }

  /// Address type used for DNS lookups.
  final InternetAddressType addressType;

  /// The client endpoint URI
  final Uri uri;

  /// The default request timeout
  late Duration timeout; // ms

  final DefaultCoapConfig _config;
  CoapIEndPoint? _endpoint;
  late final String _namespace;
  final _lock = sync.Lock();

  /// Performs a CoAP ping and gives up after the given number of milliseconds.
  Future<bool> ping({Duration? timeout}) async {
    final request =
        CoapRequest.isConfirmable(CoapCode.empty, confirmable: true);
    request.token = CoapConstants.emptyToken;
    await _prepare(request);
    _endpoint!.sendEpRequest(request);
    await _waitForReject(request, timeout ?? this.timeout);
    return request.isRejected;
  }

  /// Sends a GET request.
  /// block2Size: early negotiation blocksize (16, 32, 64, 128, 256, 512, or 1024)
  Future<CoapResponse> get(
    String path, {
    int accept = CoapMediaType.textPlain,
    int type = CoapMessageType.con,
    List<CoapOption>? options,
    int block2Size = 0,
    int maxRetransmit = 0,
    Duration? timeout,
  }) {
    final request = CoapRequest.newGet()
      ..addUriPath(path)
      ..accept = accept
      ..type = type
      ..maxRetransmit = maxRetransmit;
    if (options != null) {
      request.addOptions(options);
    }
    if (block2Size != 0) {
      request.setBlock2(CoapBlockOption.encodeSZX(block2Size), 0, m: false);
    }
    return send(request, timeout: timeout);
  }

  /// Sends a POST request.
  /// block2Size: early negotiation blocksize (16, 32, 64, 128, 256, 512, or 1024)
  Future<CoapResponse> post(
    String path, {
    required String payload,
    int format = CoapMediaType.textPlain,
    int accept = CoapMediaType.textPlain,
    int type = CoapMessageType.con,
    List<CoapOption>? options,
    int block2Size = 0,
    int maxRetransmit = 0,
    Duration? timeout,
  }) {
    final request = CoapRequest.newPost()
      ..addUriPath(path)
      ..setPayloadMedia(payload, format)
      ..accept = accept
      ..type = type
      ..maxRetransmit = maxRetransmit;
    if (options != null) {
      request.addOptions(options);
    }
    if (block2Size != 0) {
      request.setBlock2(CoapBlockOption.encodeSZX(block2Size), 0, m: false);
    }
    return send(request, timeout: timeout);
  }

  /// Sends a POST request with the specified byte payload.
  /// block2Size: early negotiation blocksize (16, 32, 64, 128, 256, 512, or 1024)
  Future<CoapResponse> postBytes(
    String path, {
    required typed.Uint8Buffer payload,
    int format = CoapMediaType.textPlain,
    int accept = CoapMediaType.textPlain,
    int type = CoapMessageType.con,
    List<CoapOption>? options,
    int block2Size = 0,
    Duration? timeout,
    int maxRetransmit = 0,
  }) {
    final request = CoapRequest.newPost()
      ..addUriPath(path)
      ..setPayloadMediaRaw(payload, format)
      ..accept = accept
      ..type = type
      ..maxRetransmit = maxRetransmit;
    if (options != null) {
      request.addOptions(options);
    }
    if (block2Size != 0) {
      request.setBlock2(CoapBlockOption.encodeSZX(block2Size), 0, m: false);
    }
    return send(request, timeout: timeout);
  }

  /// Sends a PUT request.
  /// block2Size: early negotiation blocksize (16, 32, 64, 128, 256, 512, or 1024)
  Future<CoapResponse> put(
    String path, {
    required String payload,
    int format = CoapMediaType.textPlain,
    int accept = CoapMediaType.textPlain,
    int type = CoapMessageType.con,
    List<typed.Uint8Buffer>? etags,
    MatchEtags matchEtags = MatchEtags.onMatch,
    List<CoapOption>? options,
    int block2Size = 0,
    int maxRetransmit = 0,
    Duration? timeout,
  }) {
    final request = CoapRequest.newPut()
      ..addUriPath(path)
      ..setPayloadMedia(payload, format)
      ..accept = accept
      ..type = type
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
          etags.forEach(request.addIfNoneMatchOpaque);
      }
    }
    if (block2Size != 0) {
      request.setBlock2(CoapBlockOption.encodeSZX(block2Size), 0, m: false);
    }
    return send(request, timeout: timeout);
  }

  /// Sends a PUT request with the specified byte payload.
  /// block2Size: early negotiation blocksize (16, 32, 64, 128, 256, 512, or 1024)
  Future<CoapResponse> putBytes(
    String path, {
    required typed.Uint8Buffer payload,
    int format = CoapMediaType.textPlain,
    MatchEtags matchEtags = MatchEtags.onMatch,
    List<typed.Uint8Buffer>? etags,
    int accept = CoapMediaType.textPlain,
    int type = CoapMessageType.con,
    List<CoapOption>? options,
    int block2Size = 0,
    int maxRetransmit = 0,
    Duration? timeout,
  }) {
    final request = CoapRequest.newPut()
      ..addUriPath(path)
      ..setPayloadMediaRaw(payload, format)
      ..accept = accept
      ..type = type
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
          etags.forEach(request.addIfNoneMatchOpaque);
      }
    }
    if (block2Size != 0) {
      request.setBlock2(CoapBlockOption.encodeSZX(block2Size), 0, m: false);
    }
    return send(request, timeout: timeout);
  }

  /// Sends a DELETE request
  /// block2Size: early negotiation blocksize (16, 32, 64, 128, 256, 512, or 1024)
  Future<CoapResponse> delete(
    String path, {
    int accept = CoapMediaType.textPlain,
    int type = CoapMessageType.con,
    List<CoapOption>? options,
    int block2Size = 0,
    int maxRetransmit = 0,
    Duration? timeout,
  }) {
    final request = CoapRequest.newDelete()
      ..addUriPath(path)
      ..accept = accept
      ..type = type
      ..maxRetransmit = maxRetransmit;
    if (options != null) {
      request.addOptions(options);
    }
    if (block2Size != 0) {
      request.setBlock2(CoapBlockOption.encodeSZX(block2Size), 0, m: false);
    }
    return send(request, timeout: timeout);
  }

  /// Observe
  Future<CoapObserveClientRelation> observe(
    CoapRequest request, {
    Duration? timeout,
    int maxRetransmit = 0,
  }) async {
    request
      ..observe = 0
      ..maxRetransmit = maxRetransmit;
    await _prepare(request);
    final relation = CoapObserveClientRelation(
        request, request.endpoint, _config,
        namespace: _namespace);
    () async {
      _endpoint!.sendEpRequest(request);
      final response = await _waitForResponse(request, timeout ?? this.timeout);
      if (!response.hasOption(optionTypeObserve)) {
        relation.isCancelled = true;
      }
    }();
    return relation;
  }

  /// Discovers remote resources.
  Future<Iterable<CoapWebLink>?> discover({
    String query = '',
    Duration? timeout,
  }) async {
    final discover = CoapRequest.newGet();
    discover.uriPath = CoapConstants.defaultWellKnownURI;
    if (query.isNotEmpty) {
      discover.uriQuery = query;
    }
    final links = await send(discover, timeout: timeout);
    if (links.isEmpty) {
      // If no response, return null (e.g., timeout)
      return null;
    } else if (links.contentFormat != CoapMediaType.applicationLinkFormat) {
      return <CoapWebLink>[CoapWebLink('')];
    } else {
      return CoapLinkFormat.parse(links.payloadString!);
    }
  }

  /// Send
  Future<CoapResponse> send(CoapRequest request, {Duration? timeout}) async {
    await _prepare(request);
    _endpoint!.sendEpRequest(request);
    return _waitForResponse(request, timeout ?? this.timeout);
  }

  /// Cancel ongoing observable request
  Future<void> cancelObserveProactive(
      CoapObserveClientRelation relation) async {
    final cancel = relation.newCancel();
    await send(cancel);
    relation.isCancelled = true;
  }

  /// Cancel after the fact
  void cancelObserveReactive(CoapObserveClientRelation relation) {
    relation.isCancelled = true;
  }

  /// Cancels a request (retries)
  void cancel(CoapRequest request) {
    request.isCancelled = true;
  }

  /// Cancel all ongoing requests
  void close() {
    _endpoint?.stop();
  }

  Future<void> _prepare(CoapRequest request) async {
    request.uri = uri;
    request.timestamp = DateTime.now();
    request.setEventBus(CoapEventBus(namespace: _namespace));

    // Set a default accept
    if (request.accept == CoapMediaType.undefined) {
      request.accept = CoapMediaType.textPlain;
    }

    await _lock.synchronized(() async {
      // Set endpoint if missing
      if (_endpoint == null) {
        final destination =
            await CoapUtil.lookupHost(uri.host, addressType, null);
        final socket = CoapNetworkUDP(destination, _config.defaultPort,
            namespace: _namespace);
        await socket.bind();
        _endpoint = CoapEndPoint(socket, _config, namespace: _namespace);
        await _endpoint!.start();
      }
    });

    request.endpoint = _endpoint;
  }

  /// Wait for a response.
  /// Returns the response, or null if timeout occured.
  FutureOr<CoapResponse> _waitForResponse(CoapRequest req, Duration timeout) {
    final completer = Completer<CoapResponse>();
    req.eventBus!
        .on<CoapRespondEvent>()
        .where((CoapRespondEvent e) => e.resp?.tokenString == req.tokenString)
        .take(1)
        .listen((CoapRespondEvent e) {
          e.resp?.timestamp = DateTime.now();
          completer.complete(e.resp);
        })
        .asFuture()
        .timeout(timeout, onTimeout: () {
          if (!completer.isCompleted) {
            req
              ..isTimedOut = true
              ..isCancelled = true;
            completer.complete(CoapResponse(CoapCode.empty));
          }
        });
    return completer.future;
  }

  /// Wait for a reject.
  /// Returns the rejected message, or null if timeout occured.
  FutureOr<CoapMessage> _waitForReject(CoapRequest req, Duration timeout) {
    final completer = Completer<CoapMessage>();
    req.eventBus!
        .on<CoapRejectedEvent>()
        .where((CoapRejectedEvent e) => e.msg.tokenString == req.tokenString)
        .take(1)
        .listen((CoapRejectedEvent e) {
          e.msg.timestamp = DateTime.now();
          completer.complete(e.msg);
        })
        .asFuture()
        .timeout(timeout, onTimeout: () {
          if (!completer.isCompleted) {
            req
              ..isTimedOut = true
              ..isCancelled = true;
            completer.complete(CoapMessage.withCode(CoapCode.empty));
          }
        });
    return completer.future;
  }
}
