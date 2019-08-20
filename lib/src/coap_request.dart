/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

// ignore_for_file: prefer_constructors_over_static_methods

part of coap;

/// Event classes

/// Resonse event
class CoapRespondEvent {
  /// Construction
  CoapRespondEvent(this.resp);

  /// Response
  CoapResponse resp;
}

/// Responding event
class CoapRespondingEvent {
  /// Construction
  CoapRespondingEvent(this.resp);

  /// Response
  CoapResponse resp;
}

/// Registering event
class CoapReregisteringEvent {
  /// Construction
  CoapReregisteringEvent(this.resp);

  /// Response
  CoapRequest resp;
}

/// This class describes the functionality of a CoAP Request as
/// a subclass of a CoAP Message. It provides:
/// 1. operations to answer a request by a response using respond()
/// 2. different ways to handle incoming responses: receiveResponse() or Response event
class CoapRequest extends CoapMessage {
  /// Initializes a request message.
  /// Defaults to confirmable
  CoapRequest(int code) : this.isConfirmable(code, confirmable: true);

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
    final String host = value.host;
    int port = value.port;
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
    clientEventBus.fire(CoapRespondEvent(value));
    // Add to the internal response stream
    _responseStream.add(value);
  }

  /// The endpoint for this request
  CoapIEndPoint endPoint;

  /// Uri
  CoapRequest setUri(String value) {
    String tmp = value;
    if (!value.startsWith('coap://') && !value.startsWith('coaps://')) {
      tmp = 'coap://$value';
    }
    uri = Uri.dataFromString(tmp);
    return this;
  }

  /// Resolves the destination internet address
  Future<InternetAddress> resolveDestination() async =>
      destination = await CoapUtil.lookupHost(resolveHost);

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

  /// Gets the value of a query parameter as a String,
  /// or null if the parameter does not exist.
  String getParameter(String name) {
    for (CoapOption query in getOptions(optionTypeUriQuery)) {
      final String val = query.stringValue;
      if (val.isEmpty) {
        continue;
      }
      if (val.startsWith('$name=')) {
        return val.substring(name.length + 1);
      }
    }
    return null;
  }

  /// Sends this message.
  CoapRequest send() {
    print('SJH - trace - send');
    _validateBeforeSending();
    endPoint.sendEpRequest(this);
    // Clear the internal response stream
    _responseStream.stream.drain();
    return this;
  }

  /// Sends the request over the specified endpoint.
  CoapRequest sendWithEndpoint(CoapIEndPoint endpointIn) {
    _validateBeforeSending();
    endPoint = endpointIn;
    endPoint.sendEpRequest(this);
    return this;
  }

  void _validateBeforeSending() {
    print('SJH - trace - _va;lidateBeforeSending');
    if (destination == null) {
      throw StateError(
          'CoapRequest::validateBeforeSending - Missing destination');
    }
  }

  /// Response stream, used by waitForResponse
  StreamController<CoapResponse> _responseStream =
      StreamController<CoapResponse>.broadcast();

  /// Wait for a response.
  /// Returns the response, or null if timeout occured.
  FutureOr<dynamic> waitForResponse(int millisecondsTimeout) {
    final Completer<dynamic> completer = Completer<dynamic>();
    if ((_currentResponse == null) &&
        (!isCancelled) &&
        (!isTimedOut) &&
        (!isRejected)) {
      final Future<void> sleepFuture = CoapUtil.asyncSleep(millisecondsTimeout);
      final StreamSubscription<CoapResponse> responseFuture =
          _responseStream.stream.listen((CoapResponse resp) {});
      Future.any<dynamic>(
              <Future<dynamic>>[sleepFuture, responseFuture.asFuture()])
          .then((dynamic resp) {
        _currentResponse = response;
        responseFuture.cancel();
        return completer.complete(response);
      });
      return completer.future;
    }
    return _currentResponse;
  }

  /// Fire the respond event
  void fireRespond(CoapResponse response) {
    clientEventBus.fire(CoapRespondEvent(response));
  }

  /// Fire the responding event
  void fireResponding(CoapResponse response) {
    clientEventBus.fire(CoapRespondingEvent(response));
  }

  /// Fire the reregistering event
  void fireReregistering(CoapRequest request) {
    clientEventBus.fire(CoapReregisteringEvent(request));
  }

  /// Construct a GET request.
  static CoapRequest newGet() => CoapRequest(CoapCode.methodGET);

  /// Construct a POST request.
  static CoapRequest newPost() => CoapRequest(CoapCode.methodPOST);

  /// Construct a PUT request.
  static CoapRequest newPut() => CoapRequest(CoapCode.methodPUT);

  /// Construct a DELETE request.
  static CoapRequest newDelete() => CoapRequest(CoapCode.methodDELETE);
}
