import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> sleep() =>
    Future<void>.delayed(const Duration(milliseconds: 1), () => '2000');

Future<void> main() async {
  /// Create and bind to the first(and only!) IPV6 loopback interface
  final interfaces = await NetworkInterface.list(
      includeLoopback: true,
      includeLinkLocal: true,
      type: InternetAddressType.IPv4);
  print(interfaces);
  InternetAddress loopbackAddress;
  for (final interface in interfaces) {
    for (final address in interface.addresses) {
      if (address.isLoopback) {
        loopbackAddress = address;
        break;
      }
    }
  }

  print('The selected loopback address is $loopbackAddress');

  final theSocket = await RawDatagramSocket.bind(loopbackAddress, 5683);
  print('Datagram socket ready to receive');
  print('${theSocket.address.address}:${theSocket.port}');
  theSocket.listen((RawSocketEvent e) {
    final d = theSocket.receive();
    if (d == null) {
      return;
    }

    final message = String.fromCharCodes(d.data).trim();
    print('Datagram from ${d.address.address}:${d.port}: $message');
  });

  /// Send some data
  const message = 'Hello from client';
  for (var count = 0; count <= 9; count++) {
    final sent = theSocket?.send(
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
