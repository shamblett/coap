/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

import 'dart:io';

import 'package:typed_data/typed_data.dart';

import '../coap_constants.dart';
import '../coap_message.dart';
import '../event/coap_event_bus.dart';
import 'coap_inetwork.dart';

/// UDP network
class CoapNetworkUDP implements CoapINetwork {
  /// Initialize with an address and a port
  CoapNetworkUDP({final String namespace = ''})
      : eventBus = CoapEventBus(namespace: namespace);

  final CoapEventBus eventBus;

  RawDatagramSocket? _ipv4Socket;

  RawDatagramSocket? _ipv6Socket;

  Future<RawDatagramSocket> _createClient(final InternetAddress bindAddress) =>
      RawDatagramSocket.bind(bindAddress, 0);

  Future<RawDatagramSocket> _checkExistingClient(
    final RawDatagramSocket? existingClient,
    final InternetAddress bindAddress,
  ) async {
    final RawDatagramSocket newClient;

    if (existingClient == null) {
      eventBus.fire(CoapSocketInitEvent());
      newClient = await _createClient(bindAddress);
      _receive(newClient);
    } else {
      return existingClient;
    }

    return newClient;
  }

  Future<RawDatagramSocket> _obtainClient(final InternetAddress address) async {
    final internetAddressType = address.type;

    final RawDatagramSocket client;
    if (internetAddressType == InternetAddressType.IPv4) {
      client = await _checkExistingClient(_ipv4Socket, InternetAddress.anyIPv4);
      _ipv4Socket = client;
    } else {
      client = await _checkExistingClient(_ipv6Socket, InternetAddress.anyIPv6);
      _ipv6Socket = client;
    }

    return client;
  }

  @override
  bool isClosed = false;

  @override
  Future<void> sendMessage(final CoapMessage coapRequest, final Uri uri) async {
    if (isClosed) {
      return;
    }

    final address = await lookupHost(uri);
    final uriPort = uri.port;
    final port = uriPort != 0 ? uriPort : CoapConstants.defaultPort;

    final socket = await _obtainClient(address);
    socket.send(
      coapRequest.toUdpPayload(),
      address,
      port,
    );
    enableRetransmission(coapRequest);
  }

  @override
  void close() {
    if (!isClosed) {
      _ipv4Socket?.close();
      _ipv4Socket = null;
      _ipv6Socket?.close();
      _ipv6Socket = null;
    }
    isClosed = true;
  }

  Future<void> bind() async {
    eventBus.fire(CoapSocketInitEvent());
  }

  void _receive(final RawDatagramSocket socket) {
    socket.listen(
      (final e) {
        switch (e) {
          case RawSocketEvent.read:
            final d = socket.receive();
            if (d == null) {
              return;
            }
            // d.address can differ from address with multicast
            final message =
                CoapMessage.fromUdpPayload(Uint8Buffer()..addAll(d.data));
            eventBus.fire(
              CoapMessageReceivedEvent(
                message,
                d.address,
                d.port,
                scheme: CoapConstants.secureUriScheme,
              ),
            );
            break;
          // When we manually closed the socket (no need to do anything)
          case RawSocketEvent.closed:
          // Never occurs for UDP (socket cannot be closed by a remote peer)
          case RawSocketEvent.readClosed:
          case RawSocketEvent.write:
            break;
        }
      },
      // ignore: avoid_types_on_closure_parameters
      onError: (final Object e, final StackTrace s) =>
          eventBus.fire(CoapSocketErrorEvent(e, s)),
    );
  }
}
