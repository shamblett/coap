/*
 * Package : Coap
 * Author : Jan Romann <jan.romann@uni-bremen.de>
 * Date   : 02/15/2022
 * Copyright :  Jan Romann
 */

import '../coap_request.dart';
import '../coap_response.dart';
import 'exchange.dart';

class CoapMulticastExchange extends CoapExchange {
  CoapMulticastExchange(
    CoapRequest super.request,
    super.origin, {
    required super.namespace,
  });

  final List<CoapResponse> responses = [];

  bool alreadyReceived(final CoapResponse response) {
    final filteredResponses = responses.where(
      (final element) => element.source?.address == response.source?.address,
    );

    return filteredResponses.isNotEmpty;
  }
}
