/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 */
import 'dart:async';
import 'package:coap/coap.dart';
import 'package:typed_data/typed_data.dart' as typed;

Future main(List<String> args) async {
  CoapRequest newRequest(String method) {
    switch (method) {
      case "POST":
        return CoapRequest.newPost();
      case "PUT":
        return CoapRequest.newPut();
      case "DELETE":
        return CoapRequest.newDelete();
      case "GET":
      case "DISCOVER":
      case "OBSERVE":
        return CoapRequest.newGet();
      default:
        return null;
    }
  }

  // Build the request
  final CoapRequest request = newRequest("DISCOVER");
  final Uri uri = new Uri(host: "localhost", path: "/.well-known/core");
  request.uri = uri;
  final typed.Uint8Buffer payload = new typed.Uint8Buffer();
  request.setPayloadMediaRaw(payload, CoapMediaType.textPlain);
  request.send();

  // Get the response

  CoapResponse response;
  response = await request.waitForResponse(10000);
  if (response.contentType == CoapMediaType.applicationLinkFormat) {
    final Iterable<CoapWebLink> links =
        CoapLinkFormat.parse(response.payloadString);
    if (links == null) {
      print("Failed parsing link format");
    } else {
      print("Discovered resources:");
      for (CoapWebLink link in links) {
        print(link);
      }
    }
  }
}
