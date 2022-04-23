/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * A request demonstrating a blockwise (block1) post
 */

import 'dart:async';
import 'package:coap/coap.dart';
import 'config/coap_config.dart';

FutureOr<void> main(List<String> args) async {
  final conf = CoapConfig();
  final uri = Uri(scheme: 'coap', host: 'coap.me', port: conf.defaultPort);
  final client = CoapClient(uri, conf);

  final opt = CoapOption.createUriQuery(
      '${CoapLinkFormat.title}=This is an SJH Post request');

  const payload = '''
     0                   1                   2                   3
    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |Ver| T |  TKL  |      Code     |          Message ID           |
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |   Token (if any, TKL bytes) ...
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |   Options (if any) ...
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
   |1 1 1 1 1 1 1 1|    Payload (if any) ...
   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

[...]

   Token Length (TKL):  4-bit unsigned integer.  Indicates the length of
      the variable-length Token field (0-8 bytes).  Lengths 9-15 are
      reserved, MUST NOT be sent, and MUST be processed as a message
      format error.

   Code:  8-bit unsigned integer, split into a 3-bit class (most
      significant bits) and a 5-bit detail (least significant bits),
      documented as c.dd where c is a digit from 0 to 7 for the 3-bit
      subfield and dd are two digits from 00 to 31 for the 5-bit
      subfield.  The class can indicate a request (0), a success
      response (2), a client error response (4), or a server error
      response (5).  (All other class values are reserved.)  As a
      special case, Code 0.00 indicates an Empty message.  In case of a
      request, the Code field indicates the Request Method; in case of a
      response a Response Code.  Possible values are maintained in the
      CoAP Code Registries (Section 12.1).  The semantics of requests
      and responses are defined in Section 5.''';

  try {
    print('Sending post /large-create to ${uri.host}');
    var response =
        await client.post('large-create', payload: payload, options: [opt]);
    print('/large-create response status: ${response.statusCodeString}');

    print('Sending get /large-create to ${uri.host}');
    response = await client.get('large-create');
    print('/large-create response:\n${response.payloadString}');
    print('E-Tags : ${CoapUtil.iterableToString(response.etags)}');

    client.close();
  } catch (e) {
    print('CoAP encountered an exception: $e');
  }
}
