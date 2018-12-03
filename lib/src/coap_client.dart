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

/// Provides convenient methods for accessing CoAP resources.
class CoapClient {
  /// Instantiates.
  CoapClient(this.uri, this._config);

  static CoapILogger _log = CoapLogManager('console').logger;
  static Iterable<CoapWebLink> _emptyLinks = <CoapWebLink>[CoapWebLink('')];

  /// The URI
  Uri uri;
  CoapConfig _config;

  /// The endpoint
  CoapIEndPoint endpoint;
  int _type = CoapMessageType.con;
  int _blockwise;

  /// Timeout
  int timeout = 32767;

  /// Let the client use Confirmable requests.
  CoapClient useCONs() {
    _type = CoapMessageType.con;
    return this;
  }

  /// Let the client use early negotiation for the blocksize
  /// (16, 32, 64, 128, 256, 512, or 1024). Other values will
  /// be matched to the closest logarithm dualis.
  CoapClient useEarlyNegotiation(int size) {
    _blockwise = size;
    return this;
  }

  /// Let the client use late negotiation for the block size (default).
  CoapClient useLateNegotiation() {
    _blockwise = 0;
    return this;
  }

  /// Performs a CoAP ping.
  bool ping() => doPing(timeout);

  /// Performs a CoAP ping and gives up after the given number of milliseconds.
  bool doPing(int timeout) {
    try {
      final CoapRequest request = CoapRequest(CoapCode.empty);
      request.token = CoapConstants.emptyToken;
      request.uri = uri;
      request.send().waitForResponse(timeout);
      return request.isRejected;
    } on Exception catch (e) {
      _log.warn('Exception raise pinging: $e');
    }
    return false;
  }

  /// Discovers remote resources.
  Iterable<CoapWebLink> discover() => doDiscover(null);

  /// Sends a GET request and blocks until the response is available.
  CoapResponse get() => send(CoapRequest.newGet());

  /// Sends a GET request with the specified Accept option and blocks
  /// until the response is available.
  CoapResponse getWithAccept(int acceptVal) =>
      send(accept(CoapRequest.newGet(), acceptVal));

  /// Sends a POST request and blocks until the response is available.
  CoapResponse post(String payload, [int format = CoapMediaType.textPlain]) =>
      send(CoapRequest.newPost().setPayloadMedia(payload, format));

  /// Sends a POST request with the specified Accept option and blocks
  /// until the response is available.
  CoapResponse postWithAccept(String payload, int format, int acceptVal) =>
      send(accept(
          CoapRequest.newPost().setPayloadMedia(payload, format), acceptVal));

  /// Sends a POST request with the specified byte payload and blocks
  /// until the response is available.
  CoapResponse postBytePayload(typed.Uint8Buffer payload, int format) =>
      send(CoapRequest.newPost().setPayloadMediaRaw(payload, format));

  /// Sends a POST request with the specified Accept option and byte payload.
  /// Blocks until the response is available.
  CoapResponse postBytePayloadWithAccept(typed.Uint8Buffer payload, int format,
      int acceptVal) =>
      send(accept(CoapRequest.newPost().setPayloadMediaRaw(payload, format),
          acceptVal));

  /// Sends a PUT request and blocks until the response is available.
  CoapResponse put(String payload, [int format = CoapMediaType.textPlain]) =>
      send(CoapRequest.newPut().setPayloadMedia(payload, format));

  /// Sends a PUT request with the specified Accept option and blocks
  /// until the response is available.
  CoapResponse putBytePayloadWithAccept(typed.Uint8Buffer payload, int format,
      int acceptVal) =>
      send(accept(
          CoapRequest.newPut().setPayloadMediaRaw(payload, format), acceptVal));

  /// If match
  CoapResponse putIfMatch(String payload, int format,
      List<typed.Uint8Buffer> etags) =>
      send(ifMatch(
          CoapRequest.newPut().setPayloadMedia(payload, format), etags));

  /// If match byte payload
  CoapResponse putIfMatchBytePayload(typed.Uint8Buffer payload, int format,
      List<typed.Uint8Buffer> etags) =>
      send(ifMatch(
          CoapRequest.newPut().setPayloadMediaRaw(payload, format), etags));

  /// If none match
  CoapResponse putIfNoneMatch(String payload, int format) =>
      send(ifNoneMatch(CoapRequest.newPut().setPayloadMedia(payload, format)));

  /// If none match byte payload
  CoapResponse putIfNoneMatchBytePayload(typed.Uint8Buffer payload,
      int format) =>
      send(ifNoneMatch(
          CoapRequest.newPut().setPayloadMediaRaw(payload, format)));

  /// Delete
  CoapResponse delete() => send(CoapRequest.newDelete());

  /// Validate
  CoapResponse validate(List<typed.Uint8Buffer> etags) =>
      send(eTags(CoapRequest.newGet(), etags));

  /// Observe
  CoapObserveClientRelation observe([ActionGeneric<CoapResponse> notify,
    ActionGeneric<FailReason> error]) =>
      _observe(CoapRequest.newGet().markObserve(), notify, error);

  /// Observe with accept
  CoapObserveClientRelation observeWitAccept(int acceptVal,
      [ActionGeneric<CoapResponse> notify,
        ActionGeneric<FailReason> error]) =>
      _observe(
          accept(CoapRequest.newGet().markObserve(), acceptVal), notify, error);

  /// Accept
  static CoapRequest accept(CoapRequest request, int accept) {
    request.accept = accept;
    return request;
  }

  /// If match
  static CoapRequest ifMatch(
      CoapRequest request, List<typed.Uint8Buffer> etags) {
    etags.forEach(request.addIfMatch);
    return request;
  }

  /// If none match
  static CoapRequest ifNoneMatch(CoapRequest request) {
    request.ifNoneMatch = true;
    return request;
  }

  /// Etags
  CoapRequest eTags(CoapRequest request, List<typed.Uint8Buffer> etags) {
    etags.forEach(request.addETag);
    return request;
  }

  /// Discovers remote resources.
  Iterable<CoapWebLink> doDiscover(String query) {
    final CoapRequest discover = prepare(CoapRequest.newGet());
    discover.clearUriPath().clearUriQuery().uriPath =
        CoapConstants.defaultWellKnownURI;
    if (query != null && query.isNotEmpty) {
      discover.uriQuery = query;
    }
    final CoapResponse links = discover.send().waitForResponse(timeout);
    if (links == null) {
      // If no response, return null (e.g., timeout)
      return null;
    } else if (links.contentFormat != CoapMediaType.applicationLinkFormat) {
      return _emptyLinks;
    } else {
      return CoapLinkFormat.parse(links.payloadString);
    }
  }

  /// Send
  CoapResponse send(CoapRequest request) =>
      prepare(request).send().waitForResponse(timeout);

  /// Prepare
  CoapRequest prepare(CoapRequest request) =>
      _doPrepare(request, _getEffectiveEndpoint(request));

  /// Gets the effective endpoint that the specified request
  /// is supposed to be sent over.
  CoapIEndPoint _getEffectiveEndpoint(CoapRequest request) {
    if (endpoint != null) {
      return endpoint;
    } else {
      return CoapEndpointManager.getDefaultEndpoint(request.endPoint);
    }
  }

  CoapRequest _doPrepare(CoapRequest request, CoapIEndPoint endpoint) {
    request.type = _type;
    request.uri = uri;

    if (_blockwise != 0) {
      request.setBlock2(CoapBlockOption.encodeSZX(_blockwise), false, 0);
    }

    if (endpoint != null) {
      request.endPoint = endpoint;
    }

    return request;
  }

  CoapObserveClientRelation _observe(CoapRequest request,
      ActionGeneric<CoapResponse> notify, ActionGeneric<FailReason> error) {
    final CoapObserveClientRelation relation =
        _observeAsync(request, notify, error);
    final CoapResponse response = relation.request.waitForResponse(timeout);
    if (response == null || !response.hasOption(optionTypeObserve)) {
      relation.cancelled = true;
    }
    relation.current = response;
    return relation;
  }

  CoapObserveClientRelation _observeAsync(CoapRequest request,
      ActionGeneric<CoapResponse> notify, ActionGeneric<FailReason> error) {
    final CoapIEndPoint endpoint = _getEffectiveEndpoint(request);
    final CoapObserveClientRelation relation =
    CoapObserveClientRelation(request, endpoint, _config);
    _doPrepare(request, endpoint).send();
    return relation;
  }
}
