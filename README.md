[![Build Status](https://github.com/shamblett/coap/actions/workflows/ci.yml/badge.svg)](https://github.com/shamblett/coap/actions/workflows/ci.yml)
# coap
A CoAP client library for Dart developers.
The Constrained Application Protocol ([CoAP](https://datatracker.ietf.org/doc/html/rfc7252))
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
Many examples of usage are provided in the examples directory using the [coap.me](https://coap.me/) and [californium](https://www.eclipse.org/californium/) test servers.

# Setup
* Add this as dependency in your `pubspec.yaml`:
```yaml
dependencies:
  coap:
```
* Create a `.yaml` file containing your CoAP's configurations.
    * The file name must be separated by `_`. Example: `coap_config`
    * The file name must start with `coap_config`
        * Example: `coap_config_all`. This will generate a file called `CoapConfigAll` that you will use in your code.
        * Example: `coap_config_debug`. This will generate a file called `CoapConfigDebug` that you will use in your code.
        * This file must contains at least the protocol version. See the example bellow.
          This is a valid configuration file with all possible properties: [examples/config/coap_config.yaml](./examples/config/coap_config.yaml).
* Run the command that will generate the configuration class.
    * Run `pub run build_runner build` in a Dart project;
    * Run `flutter pub run build_runner build` in a Flutter project;
      After running the command above the configuration class will be generated next to the `.yaml` configuration file.

See the [examples](./examples/) for example usage.
