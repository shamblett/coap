/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 */

import 'dart:io';
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

  // Config
  final CoapConfig conf = new CoapConfig("test/config_default.yaml");

  // Build the request
  final CoapRequest request = newRequest("DISCOVER");
  final String host = "localhost";
  final String path = ".well-known/core";
  //final String query = "rt=alpha.light";
  final Uri uri = new Uri(
      scheme: "coap", host: host, port: conf.defaultPort, path: path);
  request.uri = uri;
  await request.resolveDestination();
  CoapEndpointManager.getDefaultSpec();
  final CoapIChannel channel = new CoapUDPChannel(
      request.destination, uri.port);
  request.endPoint = new CoapEndPoint(channel, conf);
  final typed.Uint8Buffer payload = new typed.Uint8Buffer();
  request.setPayloadMediaRaw(payload, CoapMediaType.textPlain);
  print(
      "Simple client, sending request to $host with path $path, waiting for response....");
  request.send();

  // Get the response
  CoapResponse response;
  response = await request.waitForResponse(60000);
  if (response != null) {
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
  } else {
    print("No response received, closing client");
    request.cancel();
  }
}
