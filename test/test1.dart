import 'dart:io';
import 'dart:convert';

Future<void> sleep() =>
    Future<void>.delayed(const Duration(milliseconds: 1), () => '500000');

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
  print('The selected loopback address is $loopbackAddress');
  RawDatagramSocket.bind(loopbackAddress, 5683)
      .then((RawDatagramSocket socket) {
    print('Datagram socket ready to receive');
    print('${socket.address.address}:${socket.port}');
    socket.listen((RawSocketEvent e) {
      Datagram d = socket.receive();
      if (d == null) return;

      String message = new String.fromCharCodes(d.data).trim();
      print('Datagram from ${d.address.address}:${d.port}: ${message}');

      socket.send(message.codeUnits, d.address, d.port);
    });
  });
  await sleep();
}
