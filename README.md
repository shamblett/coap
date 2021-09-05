[![Build Status](https://travis-ci.org/shamblett/coap.svg?branch=master)](https://travis-ci.org/shamblett/coap)
# coap

A CoAP client library for Dart developers.

The Constrained Application Protocol ([CoAP](https://datatracker.ietf.org/doc/draft-ietf-core-coap/)) 
is a RESTful web transfer protocol for resource-constrained networks and nodes.

COAP is an implementation in Dart providing CoAP-based services to Dart applications. 

The code is a port from the C# .NET project [CoAP.NET](https://github.com/smeshlink/CoAP.NET). The dart implementation is that
of a CoAP client only, not a server although the CoAP.NET project does supply a server.

The COAP client provides many high level functions to control the request/response nature of the CoAP protocol, 
fine grained control however can be obtained by users directly constructing their own request messages. 

Configuration is achieved by editing a yaml based config file containing many of CoAP protocol configurations.

This is a full implementation of the CoAP protocol including block wise transfer, deduplication, transmission retries using
request/response token/id matching, piggy-backed and separate response handling is also supported. Proxying options can be set in request messages however full proxying support is
not guaranteed. All CoAP options(if-match, if-none match, uri path/query, location path/query, content format, max age, 
etags et al.) are supported  
 
 Observation of resources is supported with the client 'listening' for observed resource updates 
 when configured for this. The client supports both IPV4 and IPV6 communications and multicast operation. CoAP 
 over DTLS(secure CoAP) is not supported.

Many examples of usage are provided in the examples directory both using a .NET based CoAP server for local testing
and testing using the [coap.me](http://coap.me/) test server. Also a fully populated default configuration
file is present in the examples directory.

# Setup

* Add this as dependency in your `pubspec.yaml`:

````yaml
dependencies:
  coap:
````

* Create a `.yaml` file containing your CoAP's configurations.
  * The file name must be separated by `_`. Example: `coap_config`
  * The file name must start with `coap_config`
    * Example: `coap_config_all`. This will generate a file called `CoapConfigAll` that you will use in your code.
    * Example: `coap_config_debug`. This will generate a file called `CoapConfigDebug` that you will use in your code.
    * This file must contains at least the protocol version. See the example bellow.

This is a valid configuration file with all possible properties:

````yaml
# An example COAP config file
# Syntax is YAML

# Protocol section
version: "RFC7252" # (this field is required)
defaultPort: 5684
defaultSecurePort: 5684
httpPort: 8080
ackTimeout: 3000 # ms
ackRandomFactor: 1.5
ackTimeoutScale: 2.0
maxRetransmit: 8
maxMessageSize: 1024
defaultBlockSize: 512
blockwiseStatusLifetime: 60000 # ms
useRandomIDStart: true
useRandomTokenStart: true
notificationMaxAge: 128000 # ms
notificationCheckIntervalTime: 86400000 # ms
notificationCheckIntervalCount: 100 # ms
notificationReregistrationBackoff: 2000 # ms
cropRotationPeriod: 2000 # ms
exchangeLifetime: 1247000 # ms
markAndSweepInterval: 10000 # ms
channelReceivePacketSize: 2048
deduplicator: "MarkAndSweep" # CropRotayion or Noop

# Logging section

# Target is none or console
logTarget: "console"
# Log levels
logError: "true"
logDebug: "true"
logWarn: "true"
logInfo: "true"
````

* Run the command that will generate the configuration class.

  * Run `pub run build_runner build` in a Dart project;
  * Run `flutter pub run build_runner build` in a Flutter project;

After running the command above the configuration class will be generated next to the `.yaml` configuration file.

# Example

This is a Dart Native program example that uses the [coap.me](http://coap.me/) server to fetch the word "world". Note that to run it you will need to generate your own configuration file.

````dart
import 'dart:async';
import 'dart:io';
import 'package:coap/coap.dart';
import '../config/coap_config_debug.dart';

FutureOr<void> main(List<String> args) async {
  // Create a configuration class. Logging levels can be specified in
  // the configuration file
  final conf = CoapConfigDebug();

  // Build the request uri, note that the request paths/query parameters can be changed
  // on the request anytime after this initial setup.
  const host = 'coap.me';

  final uri = Uri(scheme: 'coap', host: host, port: conf.defaultPort);

  // Create the client.
  // The method we are using creates its own request so we do not
  // need to supply one.
  // The current request is always available from the client.
  final client = CoapClient(uri, conf);

  // Adjust the response timeout if needed, defaults to 32767 milliseconds
  //client.timeout = 10000;

  // Create the request for the get request
  final request = CoapRequest.newGet();
  request.addUriPath('hello');
  client.request = request;

  print('EXAMPLE - Sending get request to $host, waiting for response....');

  final response = await client.get();
  print('EXAMPLE - response received');
  print(response.payloadString);

  // Clean up
  client.close();

  exit(0);
}
````