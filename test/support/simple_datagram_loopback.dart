import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ignore_for_file: omit_local_variable_types
// ignore_for_file: unnecessary_final
// ignore_for_file: cascade_invocations
// ignore_for_file: avoid_annotating_with_dynamic
// ignore_for_file: avoid_types_on_closure_parameters
// ignore_for_file: flutter_style_todos
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: avoid_print

Future<void> sleep() =>
    Future<void>.delayed(const Duration(milliseconds: 1), () => '2000');

Future<void> main() async {
  /// Create and bind to the first(and only!) IPV6 loopback interface
  final List<NetworkInterface> interfaces = await NetworkInterface.list(
      includeLoopback: true,
      includeLinkLocal: true,
      type: InternetAddressType.IPv4);
  print(interfaces);
  InternetAddress loopbackAddress;
  for (final NetworkInterface interface in interfaces) {
    for (final InternetAddress address in interface.addresses) {
      if (address.isLoopback) {
        loopbackAddress = address;
        break;
      }
    }
  }

  print('The selected loopback address is $loopbackAddress');

  final RawDatagramSocket theSocket =
      await RawDatagramSocket.bind(loopbackAddress, 5683);
  print('Datagram socket ready to receive');
  print('${theSocket.address.address}:${theSocket.port}');
  theSocket.listen((RawSocketEvent e) {
    final Datagram d = theSocket.receive();
    if (d == null) {
      return;
    }

    final String message = String.fromCharCodes(d.data).trim();
    print('Datagram from ${d.address.address}:${d.port}: $message');
  });

  /// Send some data
  const String message = 'Hello from client';
  for (int count = 0; count <= 9; count++) {
    final int sent = theSocket?.send(
        const Utf8Codec().encode(message), loopbackAddress, 5683);
    if (sent != message.length) {
      print('Boo, we didnt send 4 ints, we sent $sent');
    } else {
      print('Hoorah $sent ints sent');
    }
    await sleep();
  }
  print('Closing socket');
  theSocket.close();
}
