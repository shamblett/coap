/*
 * Package : Coap
 * Author : Jan Romann <jan.romann@uni-bremen.de>
 * Date   : 02/15/2022
 * Copyright :  Jan Romann
 */

import '../coap_request.dart';
import '../coap_response.dart';
import 'coap_exchange.dart';

class CoapMulticastExchange extends CoapExchange {
  CoapMulticastExchange(
    final CoapRequest super.request,
    super.origin, {
    required final super.namespace,
  });

  final List<CoapResponse> responses = [];

  bool alreadyReceived(final CoapResponse response) {
    final filteredResponses = responses.where(
      (final element) =>
          element.source?.address.address == response.source?.address.address,
    );

    return filteredResponses.isNotEmpty;
  }
}
