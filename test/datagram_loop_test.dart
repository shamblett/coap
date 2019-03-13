import 'dart:io';
import 'dart:convert';

void connect(InternetAddress clientAddress, int port) {
  Future.wait([RawDatagramSocket.bind(InternetAddress, port)]).then((values) {
    RawDatagramSocket udpSocket = values[0];
    udpSocket.listen((RawSocketEvent e) {
      print(e);
      switch (e) {
        case RawSocketEvent.read:
          Datagram dg = udpSocket.receive();
          if (dg != null) {
            dg.data.forEach((x) => print(x));
          }
          udpSocket.writeEventsEnabled = true;
          break;
        case RawSocketEvent.write:
          udpSocket.send(
              new Utf8Codec().encode('Hello from client'), clientAddress, port);
          break;
        case RawSocketEvent.closed:
          print('Client disconnected.');
      }
    });
  });
}

void main() async {
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
  print("Connecting to server..");
  int port = 5683;
  connect(loopbackAddress, port);
}
