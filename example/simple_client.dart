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
  final CoapConfig conf = CoapConfig(File('test/config_logging.yaml'));

  // Build the request
  final CoapRequest request = newRequest('DISCOVER');
  const String host = 'localhost';
  //const String host = '172.17.215.3';
  //const String host = '172.17.199.238';
  //const String host = 'coap.me';
  //const String path = '.well-known/core';
  //const String path = '/time';
  //const String path = '/hello';
  const String path = '/mirror';
  //const String path = '/fibonacci';
  //const String query = 'n=10';
  //final Uri uri =
  //  Uri(scheme: 'coap', host: host, port: conf.defaultPort, path: path, query:query);
  final Uri uri =
  Uri(scheme: 'coap', host: host, port: conf.defaultPort, path: path);
  request.uri = uri;
  await request.resolveDestination(InternetAddressType.IPv4);
  CoapEndpointManager.getDefaultSpec();
  final CoapIChannel channel = CoapUDPChannel(request.destination, uri.port);
  request.endPoint = CoapEndPoint(channel, conf);
  final typed.Uint8Buffer payload = typed.Uint8Buffer();
  request.setPayloadMediaRaw(payload, CoapMediaType.textPlain);
  print(
      'Simple client, sending request to $host with path $path, waiting for response....');
  request.send();

  // Get the response
  print('Awaiting response.....');
  final CoapResponse response = await request.waitForResponse(10000);
  if (response != null) {
    print('Response received......');
    if (response.contentType == CoapMediaType.applicationLinkFormat) {
      final Iterable<CoapWebLink> links =
      CoapLinkFormat.parse(response.payloadString);
      if (links == null) {
        print('No resources discovered');
      } else {
        print('Discovered resources:');
        links.forEach(print);
      }
    } else if (response.contentType == CoapMediaType.textPlain) {
      print('Path resource, data is ....');
      print(response.payloadString);
    }
  } else {
    print('No response received, closing client');
    request.cancel();
  }
}
