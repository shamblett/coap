/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// This class describes the functionality of a CoAP Request as
/// a subclass of a CoAP Message. It provides:
/// 1. operations to answer a request by a response using respond()
/// 2. different ways to handle incoming responses:
/// receiveResponse() or Response event.
class CoapRequest extends CoapMessage {
  /// Default
  CoapRequest();

  /// Initializes a request message.
  /// Defaults to confirmable
  CoapRequest.withType(int code) : this.isConfirmable(code, confirmable: true);

  /// Initializes a request message.
  /// True if the request is Confirmable
  CoapRequest.isConfirmable(int code, {bool confirmable})
      : super.withCode(
            confirmable ? CoapMessageType.con : CoapMessageType.non, code) {
    _method = code;
  }

  int _method;

  /// The request method(code)
  int get method => _method;

  /// Indicates whether this request is a multicast request or not.
  bool multicast;

  Uri _uri;

  /// The URI of this CoAP message.
  Uri get uri => _uri ??= Uri(
      scheme: CoapConstants.uriScheme,
      host: uriHost ?? 'localhost',
      port: uriPort,
      path: uriPath,
      query: uriQuery);

  set uri(Uri value) {
    if (value == null) {
      return;
    }
    final host = value.host;
    var port = value.port;
    if ((host.isNotEmpty) &&
        (!CoapUtil.regIP.hasMatch(host)) &&
        (host != 'localhost')) {
      uriHost = host;
    }
    if (port <= 0) {
      if ((value.scheme.isNotEmpty) ||
          (value.scheme == CoapConstants.uriScheme)) {
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

  CoapResponse _currentResponse;

  /// The response to this request.
  CoapResponse get response => _currentResponse;

  set response(CoapResponse value) {
    _currentResponse = value;
    _currentResponse.timestamp = DateTime.now();
    _eventBus.fire(CoapRespondEvent(value));
    // Add to the internal response stream
    _responseStream.add(value);
  }

  /// The endpoint for this request
  CoapIEndPoint endpoint;

  /// Resolves the destination internet address
  Future<CoapInternetAddress> resolveDestination(
          InternetAddressType addressType) async =>
      destination =
          await CoapUtil.lookupHost(resolveHost, addressType, bindAddress);

  /// Sets CoAP's observe option. If the target resource of this request
  /// responds with a success code and also sets the observe option, it will
  /// send more responses in the future whenever the resource's state changes.
  CoapRequest markObserve() {
    observe = 0;
    return this;
  }

  /// Sets CoAP's observe option to the value of 1 to proactively cancel.
  CoapRequest markObserveCancel() {
    observe = 1;
    return this;
  }

  /// Sends this message.
  CoapRequest send() {
    _validateBeforeSending();
    endpoint.sendEpRequest(this);
    timestamp = DateTime.now();
    // Clear the internal response stream
    _responseStream.stream.drain();
    return this;
  }

  /// Sends the request over the specified endpoint.
  CoapRequest sendWithEndpoint(CoapIEndPoint endpointIn) {
    _validateBeforeSending();
    endpoint = endpointIn;
    endpoint.sendEpRequest(this);
    timestamp = DateTime.now();
    return this;
  }

  void _validateBeforeSending() {
    if (destination == null) {
      throw StateError(
          'CoapRequest::validateBeforeSending - Missing destination');
    }
  }

  final StreamController<CoapResponse> _responseStream =
      StreamController<CoapResponse>.broadcast();

  /// Response stream
  Stream<CoapResponse> get responses => _responseStream.stream;

  /// Wait for a response.
  /// Returns the response, or null if timeout occured.
  FutureOr<CoapResponse> waitForResponse(int millisecondsTimeout) {
    final completer = Completer<CoapResponse>();
    if ((_currentResponse == null) &&
        (!isCancelled) &&
        (!isTimedOut) &&
        (!isRejected)) {
      final response = _responseStream.stream.take(1);
      response
          .listen((CoapResponse resp) {
            _currentResponse = resp;
            _currentResponse.timestamp = DateTime.now();
            completer.complete(_currentResponse);
          })
          .asFuture()
          .timeout(Duration(milliseconds: millisecondsTimeout), onTimeout: () {
            if (!completer.isCompleted) {
              completer.complete(null);
            }
          });
      return completer.future;
    }
    return completer.future;
  }

  /// Fire the responding event
  void fireResponding(CoapResponse response) {
    _eventBus.fire(CoapRespondingEvent(response));
  }

  /// Fire the reregistering event
  void fireReregistering(CoapRequest request) {
    _eventBus.fire(CoapReregisteringEvent(request));
  }

  /// Stop a request, effectively cancels the request
  void stop() {
    endpoint.stop();
  }

  @override
  String toString() => '\n<<< Request Message >>>${super.toString()}';

  /// Construct a GET request.
  static CoapRequest newGet() => CoapRequest.withType(CoapCode.methodGET);

  /// Construct a POST request.
  static CoapRequest newPost() => CoapRequest.withType(CoapCode.methodPOST);

  /// Construct a PUT request.
  static CoapRequest newPut() => CoapRequest.withType(CoapCode.methodPUT);

  /// Construct a DELETE request.
  static CoapRequest newDelete() => CoapRequest.withType(CoapCode.methodDELETE);
}
