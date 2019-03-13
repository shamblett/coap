/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/04/2017
 * Copyright :  S.Hamblett
 */
import 'dart:async';
import 'dart:io';

Future<void> sleep() =>
    Future<void>.delayed(const Duration(milliseconds: 1), () => '500');

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
  //socket = await RawDatagramSocket.bind(
  //  loopbackAddress, 5683, reuseAddress: true, reusePort: true, ttl: 5);

  socket = await RawDatagramSocket.bind(
      loopbackAddress.address, 5683);

  final List<int> sendData = <int>[41, 42, 43, 44];

  /// Start
  print('Starting send test');
  const bool go = true;
  do {
    /// Send some data
    final int sent = socket.send(sendData, loopbackAddress, 5683);
    if (sent != sendData.length) {
      print('Boo, we didnt send 4 ints, we sent $sent');
    } else {
      print('Hoorah $sent ints sent');
    }
    await sleep();
  } while (go);
}
