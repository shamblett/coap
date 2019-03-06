/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/04/2017
 * Copyright :  S.Hamblett
 */
import 'dart:io';
import 'package:collection/collection.dart';

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
  socket = await RawDatagramSocket.bind(loopbackAddress, 5683);

  final List<int> sendData = <int>[41, 42, 43, 44];

  /// Receive it
  print('Receiving the data');
  for (int i = 0; i < 10; i++) {
    /// Send some data
    print('Sending some data');
    final int sent = socket.send(sendData, loopbackAddress, 5683);
    if (sent != sendData.length) {
      print('Boo, we didnt send 4 ints');
    }
    final Datagram rx = socket.receive();
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
  }
}
