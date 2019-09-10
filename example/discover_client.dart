/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 06/06/2018
 * Copyright :  S.Hamblett
 *
 * A simple discover request using .well-known/core to discover a servers reource list
 */

import 'dart:async';
import 'dart:io';
import 'package:coap/coap.dart';

FutureOr<void> main(List<String> args) async {
  // Config
  final CoapConfig conf = CoapConfig(File('example/config_all.yaml'));

  // Build the request uri, note that the request paths/query parameters can be changed
  // on the request anytime after this initial setup.
  const String host = 'localhost';
  //const String host = '172.17.215.3';
  //const String host = '172.17.199.238';
  //const String host = 'coap.me';
  const String path = '.well-known/core';
  //const String path = '/time';
  //const String path = '/hello';
  //const String path = '/mirror';
  //const String path = '/fibonacci';
  //const String path = '/separate';
  //const String path = '/careless';
  //const String query = 'n=10';

  final Uri uri = Uri(scheme: 'coap', host: host, port: conf.defaultPort);

  // Create a default request
  final CoapRequest request = CoapRequest();
  // Set any other query parameters here

  // Create the client
  final CoapClient client = CoapClient(uri, conf, request);

  // Adjust the send timeout if needed, defaults to 32767 milliseconds
  client.timeout = 10000;

  print(
      'Discover client, sending request to $host with path $path, waiting for response....');

  // Do the discovery, note that using this method forces the path to be .well-known/core
  final Iterable<CoapWebLink> links = await client.discover(null);

  if (links == null) {
    print('No resources discovered');
  } else {
    print('Discovered resources:');
    links.forEach(print);
  }
}
