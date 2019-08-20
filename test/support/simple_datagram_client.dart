import 'dart:io';
import 'package:hex/hex.dart';
import 'package:pedantic/pedantic.dart';

void main() async {
  /// Create and bind to the first(and only!) IPV4 loopback interface
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

  unawaited(RawDatagramSocket.bind(loopbackAddress, 5683)
      .then((RawDatagramSocket socket) {
    print('Datagram socket ready to receive');
    print('${socket.address.address}:${socket.port}');
    socket.listen((RawSocketEvent e) {
      final Datagram d = socket.receive();
      if (d == null) {
        return;
      }
      print('Received: ${HEX.encode(d.data)}');
    });
  }));
}
