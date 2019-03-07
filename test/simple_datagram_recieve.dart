/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/04/2017
 * Copyright :  S.Hamblett
 */
import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';

Future<void> sleep() =>
    Future<void>.delayed(const Duration(milliseconds: 1), () => '500');

Datagram receiveDatagram(RawDatagramSocket socket) => socket.receive();

void main() async {
  /// Create and bind to the first(and only!) IPV6 loopback interface
  RawDatagramSocket socket;
  final List<NetworkInterface> interfaces = await NetworkInterface.list(
      includeLoopback: true,
      includeLinkLocal: true,
      type: InternetAddressType.IPv4);
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
  socket = await RawDatagramSocket.bind(
      loopbackAddress, 5683, reuseAddress: true, reusePort: true, ttl: 5);

  final List<int> sendData = <int>[41, 42, 43, 44];

  /// Start
  print('Starting recieve test');
  const bool go = true;
  do {
    final Datagram rx = receiveDatagram(socket);
    if (rx == null) {
      print('Boo no date received at all!');
    } else {
      print('The data is : ${rx.data}');
      if (const IterableEquality().equals(rx.data, sendData)) {
        print('Hoorah a match');
      } else {
        print('Boo no match');
      }
    }
    await sleep();
  } while (go);
}
