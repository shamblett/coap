/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/06/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Doesn't do much yet except for setting a simple token. Notice that empty
/// tokens must be represented as byte array of length 0 (not null).
class CoapTokenLayer extends CoapAbstractLayer {
  final Random _random = Random();

  /// Constructs a new token layer.
  CoapTokenLayer(DefaultCoapConfig config);

  @override
  void sendRequest(
      CoapINextLayer nextLayer, CoapExchange? exchange, CoapRequest request) {
    request.token ??= _newToken();
    super.sendRequest(nextLayer, exchange, request);
  }

  @override
  void sendResponse(
      CoapINextLayer nextLayer, CoapExchange exchange, CoapResponse? response) {
    // A response must have the same token as the request it belongs to. If
    // the token is empty, we must use a byte array of length 0.
    response!.token ??= exchange.currentRequest!.token;
    super.sendResponse(nextLayer, exchange, response);
  }

  @override
  void receiveRequest(
      CoapINextLayer nextLayer, CoapExchange exchange, CoapRequest request) {
    if (exchange.currentRequest!.token == null) {
      throw StateError('Received requests\'s token cannot be null, use '
          'byte[0] for empty tokens');
    }
    super.receiveRequest(nextLayer, exchange, request);
  }

  @override
  void receiveResponse(
      CoapINextLayer nextLayer, CoapExchange exchange, CoapResponse response) {
    if (response.token == null) {
      throw StateError('Received response\'s token cannot be null, use '
          'byte[0] for empty tokens');
    }
    super.receiveResponse(nextLayer, exchange, response);
  }

  typed.Uint8Buffer _newToken() {
    final buff = typed.Uint8Buffer()
      ..addAll(List<int>.generate(8, (i) => _random.nextInt(256)));
    return buff;
  }
}
