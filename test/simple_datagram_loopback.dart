/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/04/2017
 * Copyright :  S.Hamblett
 */
import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<void> sleep() =>
    Future<void>.delayed(const Duration(milliseconds: 1), () => '5000');

Future<void> sleep1() =>
    Future<void>.delayed(const Duration(milliseconds: 1), () => '200');

Datagram receiveDatagram(RawDatagramSocket socket) => socket.receive();

void main() async {
  /// Create and bind to the first(and only!) IPV6 loopback interface
  RawDatagramSocket socket;
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
  print('The selected loopback address is $loopbackAddress');

  socket = await RawDatagramSocket.bind(loopbackAddress.address, 5683);

  /// Start
  print('Starting loop');
  socket.asBroadcastStream().listen((RawSocketEvent e) {
    do {
      //print(e);
      switch (e) {
        case RawSocketEvent.read:
          Datagram dg = socket.receive();
          if (dg != null) {
            dg.data.forEach((x) => print(x));
          }
          socket.writeEventsEnabled = true;
          break;
        case RawSocketEvent.write:
          socket.send(const Utf8Codec().encode('Hello from client'),
              loopbackAddress, 5683);
          break;
        case RawSocketEvent.closed:
          print('Client disconnected.');
      }
      sleep1();
    } while (true);
  });
  await sleep();
}
