/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:io';
import 'package:coap/coap.dart';
import 'package:typed_data/typed_data.dart' as typed;

FutureOr<void> main(List<String> args) async {
  CoapRequest newRequest(String method) {
    switch (method) {
      case 'POST':
        return CoapRequest.newPost();
      case 'PUT':
        return CoapRequest.newPut();
      case 'DELETE':
        return CoapRequest.newDelete();
      case 'GET':
      case 'DISCOVER':
      case 'OBSERVE':
        return CoapRequest.newGet();
      default:
        return null;
    }
  }

  // Config
  final CoapConfig conf = CoapConfig(
      File('test/config_default.yaml'));

  // Build the request
  final CoapRequest request = newRequest('DISCOVER');
  const String host = 'localhost';
  const String path = '.well-known/core';
  //final String query = 'rt=alpha.light';
  final Uri uri = Uri(
      scheme: 'coap', host: host, port: conf.defaultPort, path: path);
  request.uri = uri;
  await request.resolveDestination();
  print('SJH - isLinkLocal - ${request.destination.isLinkLocal}');
  print('SJH - isLoopback - ${request.destination.isLoopback}');
  print('SJH - isLinkMulticast - ${request.destination.isMulticast}');
  print('SJH - type - ${request.destination.type}');
  CoapEndpointManager.getDefaultSpec();
  final CoapIChannel channel = CoapUDPChannel(
      request.destination, uri.port);
  request.endPoint = CoapEndPoint(channel, conf);
  final typed.Uint8Buffer payload = typed.Uint8Buffer();
  request.setPayloadMediaRaw(payload, CoapMediaType.textPlain);
  print(
      'Simple client, sending request to $host with path $path, waiting for response....');
  request.send();

  // Get the response
  final CoapResponse response = await request.waitForResponse(60000);
  if (response != null) {
    if (response.contentType == CoapMediaType.applicationLinkFormat) {
      final Iterable<CoapWebLink> links =
      CoapLinkFormat.parse(response.payloadString);
      if (links == null) {
        print('Failed parsing link format');
      } else {
        print('Discovered resources:');
        links.forEach(print);
      }
    }
  } else {
    print('No response received, closing client');
    request.cancel();
  }
}