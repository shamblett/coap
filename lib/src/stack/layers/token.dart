/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/06/2018
 * Copyright :  S.Hamblett
 */

import 'dart:math';

import 'package:typed_data/typed_data.dart';

import '../../coap_constants.dart';
import '../../coap_request.dart';
import '../../coap_response.dart';
import '../../net/exchange.dart';
import '../base_layer.dart';

/// Doesn't do much yet except for setting a simple token. Notice that empty
/// tokens must be represented as byte array of length 0 (not null).
class TokenLayer extends BaseLayer {
  final Random _random = Random();

  @override
  void sendRequest(
    final CoapExchange initialExchange,
    final CoapRequest request,
  ) {
    request.token ??= _newToken();
    super.sendRequest(initialExchange, request);
  }

  @override
  void sendResponse(
    final CoapExchange initialExchange,
    final CoapResponse response,
  ) {
    // A response must have the same token as the request it belongs to. If
    // the token is empty, we must use a byte array of length 0.
    response.token ??= initialExchange.currentRequest!.token;
    super.sendResponse(initialExchange, response);
  }

  @override
  void receiveRequest(
    final CoapExchange initialExchange,
    final CoapRequest request,
  ) {
    if (initialExchange.currentRequest!.token == null) {
      throw StateError(
        "Received requests's token cannot be null, use "
        'byte[0] for empty tokens',
      );
    }
    super.receiveRequest(initialExchange, request);
  }

  @override
  void receiveResponse(
    final CoapExchange initialExchange,
    final CoapResponse response,
  ) {
    if (response.token == null) {
      throw StateError(
        "Received response's token cannot be null, use "
        'byte[0] for empty tokens',
      );
    }
    super.receiveResponse(initialExchange, response);
  }

  Uint8Buffer _newToken() {
    final buff = Uint8Buffer()
      ..addAll(
        List<int>.generate(
          CoapConstants.tokenLength,
          (final i) => _random.nextInt(256),
        ),
      );
    return buff;
  }
}
