import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:pedantic/pedantic.dart';

Future<void> sleep() =>
    Future<void>.delayed(const Duration(milliseconds: 1), () => '1000');

void main() async {
  /// Create and bind to the first(and only!) IPV6 loopback interface
  final List<NetworkInterface> interfaces = await NetworkInterface.list(
      includeLoopback: true,
      includeLinkLocal: true,
      type: InternetAddressType.IPv6);
  print(interfaces);
  InternetAddress loopbackAddress;
  for (NetworkInterface interface in interfaces) {
    for (InternetAddress address in interface.addresses) {
      if (address.isLoopback) {
        loopbackAddress = address;
        break;
      }
    }
  }
  RawDatagramSocket theSocket;
  print('The selected loopback address is $loopbackAddress');

  unawaited(RawDatagramSocket.bind(loopbackAddress, 5683)
      .then((RawDatagramSocket socket) {
    theSocket = socket;
    print('Datagram socket ready to receive');
    print('${socket.address.address}:${socket.port}');
    socket.listen((RawSocketEvent e) {
      final Datagram d = socket.receive();
      if (d == null) {
        return;
      }

      final String message = String.fromCharCodes(d.data).trim();
      print('Datagram from ${d.address.address}:${d.port}: $message');
    });
  }));

  /// Send some data
  const bool go = true;
  const String message = 'Hello from client';
  do {
    final int sent = theSocket?.send(
        const Utf8Codec().encode(message), loopbackAddress, 5683);
    if (sent != message.length) {
      print('Boo, we didnt send 4 ints, we sent $sent');
    } else {
      print('Hoorah $sent ints sent');
    }
    await sleep();
  } while (go);
}
