import 'dart:async';
import 'dart:io';
import 'package:hex/hex.dart';

// ignore_for_file: omit_local_variable_types
// ignore_for_file: unnecessary_final
// ignore_for_file: cascade_invocations
// ignore_for_file: avoid_annotating_with_dynamic
// ignore_for_file: avoid_types_on_closure_parameters
// ignore_for_file: flutter_style_todos
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: avoid_print

Future<void> main() async {
  /// Create and bind to the first(and only!) IPV4 loopback interface
  final List<NetworkInterface> interfaces = await NetworkInterface.list(
      includeLoopback: false,
      includeLinkLocal: false,
      type: InternetAddressType.IPv4);
  print(interfaces);
  InternetAddress ipAddress;
  for (final NetworkInterface interface in interfaces) {
    for (final InternetAddress address in interface.addresses) {
      if (!address.isLoopback) {
        ipAddress = address;
        break;
      }
    }
  }

  print('The selected address is $ipAddress');

  await RawDatagramSocket.bind(ipAddress, 5683)
      .then((RawDatagramSocket socket) {
    print('Datagram socket ready to receive');
    print('Waiting on ${socket.address.address}:${socket.port} .....');
    socket.listen((RawSocketEvent e) {
      switch (e) {
        case RawSocketEvent.write:
          print('Write recieved - $e');
          final Datagram d = socket.receive();
          if (d == null) {
            break;
          }
          print('Received: ${HEX.encode(d.data)}');
          break;
        case RawSocketEvent.read:
          print('Read recieved - $e');
          final Datagram d = socket.receive();
          if (d == null) {
            break;
          }
          print('Received: ${HEX.encode(d.data)}');
          break;
        case RawSocketEvent.closed:
          print('Closed received - $e');
          break;
        default:
          print('Default');
      }
    });
  });

  await Future<void>.delayed(const Duration(milliseconds: 400000));
}
