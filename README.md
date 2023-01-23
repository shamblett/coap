[![Build Status](https://github.com/shamblett/coap/actions/workflows/ci.yml/badge.svg)](https://github.com/shamblett/coap/actions/workflows/ci.yml)
# coap
The Constrained Application Protocol is a RESTful web transfer protocol for resource-constrained networks and nodes.
The CoAP library is an implementation in Dart providing a CoAP client, the code was initially a port from the C# .NET project [CoAP.NET](https://github.com/smeshlink/CoAP.NET).

## Features
* CoAP over UDP [RFC 7252](https://tools.ietf.org/html/rfc7252)
* Observe resources [RFC 7641](https://tools.ietf.org/html/rfc7641)
* Block-wise transfers [RFC 7959](https://tools.ietf.org/html/rfc7959)
* FETCH, PATCH, and iPATCH methods [RFC 8132](https://www.rfc-editor.org/rfc/rfc8132.html)
* Extended Token Length [RFC 8974](https://tools.ietf.org/html/rfc8974)
* Multicast over UDP (not DTLS)
* **Experimental**: CoAP over DTLS, using FFI and the [dtls2](https://pub.dev/packages/dtls2) package for binding to OpenSSL
* **Experimental**: Request proxying

### Roadmap
* CoAP over TCP/TLS [RFC 8323](https://tools.ietf.org/html/rfc8323)

## Example

```dart
FutureOr<void> main() async {
  final conf = CoapConfig();
  final uri = Uri(scheme: 'coap', host: 'coap.me', port: conf.defaultPort);
  final client = CoapClient(uri, conf);

  try {
    final response =
        await client.get('multi-format', accept: CoapMediaType.textPlain);
    print('/multi-format response payload: ${response.payloadString}');
  } on Exception catch (e) {
    print('CoAP encountered an exception: $e');
  }

  client.close();
}
```

For more detailed examples, see [examples](./example/).

## Setup
* Add the dependencies in your `pubspec.yaml`:
```yaml
dependencies:
  coap: ^4.2.1

devDependencies:
  build_runner: ^2.1.11
```
* Create a `.yaml` file containing your CoAP's configurations:
  * The file name must be separated by `_` and must start with `coap_config`
    * Example: `coap_config_all`. This will generate a file called `CoapConfigAll` that you will use in your code.
    * Example: `coap_config_debug`. This will generate a file called `CoapConfigDebug` that you will use in your code.
    * This file must contain at least the protocol version.
      This is a valid configuration file with all possible properties: [example/config/coap_config.yaml](./example/config/coap_config.yaml).
* Run the command that will generate the configuration class:
  * Run `dart pub run build_runner build` in your Dart project
  * Run `flutter pub run build_runner build` in your Flutter project
    After running the command above the configuration class will be generated next to the `.yaml` configuration file.

## Considerations

### Binaries for DTLS

If you are planning to use DTLS with OpenSSL, note that not all platforms
support OpenSSL natively (iOS and Windows for example), in which case you need
to ship the required binaries with your app.
Also see the [dtls2](https://pub.dev/packages/dtls2) package's README for
more information.

### Connectivity

If connectivity is lost, the CoAP client will continuously try to re-initalize the socket. The library relies heavily on futures however, which might not survive in Flutter when the app runs in the background or when the display of the device is turned off. In this case, you might need to extend the `WidgetsBindingObserver` class and re-initialize the `CoapClient` in `didChangeAppLifecycleState` on `AppLifecycleState.resumed`.
