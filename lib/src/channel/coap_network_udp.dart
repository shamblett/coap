/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// UDP network
class CoapNetworkUDP implements CoapINetwork {
  /// Initialize with an address and a port
  CoapNetworkUDP(this.address, this.port,
      {required this.namespace, required this.config}) {
    _eventBus = CoapEventBus(namespace: namespace);
  }

  final CoapILogger? _log = CoapLogManager().logger;

  late final CoapEventBus _eventBus;

  /// The internet address
  @override
  CoapInternetAddress? address;

  /// The port to use for sending.
  @override
  int? port;

  /// The namespace to use
  @override
  String namespace = '';

  final DefaultCoapConfig config;

  @override
  final StreamController<List<int>> _data =
      StreamController<List<int>>.broadcast();

  RawDatagramSocket? _socket;
  DtlsClientConnection? _dtlsConnection;
  bool _bound = false;

  /// The incoming data stream, call receive() to instigate
  /// data reception
  @override
  Stream<List<int>> get data => _data.stream;

  /// UDP socket
  RawDatagramSocket? get socket => _socket;

  @override
  int send(typed.Uint8Buffer data) {
    try {
      if (_bound) {
        final bytes =
            Uint8List.view(data.buffer, data.offsetInBytes, data.length);
        if (config.dtlsUse) {
          _dtlsConnection?.send(bytes);
        } else {
          _socket?.send(bytes, address!.address, port!);
        }
      }
    } on SocketException catch (e) {
      _log!.error(
          'CoapNetworkUDP Recieve - severe error - socket exception : $e');
    } on Exception catch (e) {
      _log!.error('CoapNetworkUDP Send - severe error : $e');
    }
    return -1;
  }

  @override
  void receive() {
    try {
      final processFrame = (m) {
        final buff = typed.Uint8Buffer();
        if (m.isNotEmpty) {
          _data.add(m.toList());
          buff.addAll(m.toList());
          final rxEvent = CoapDataReceivedEvent(buff, address);
          _eventBus.fire(rxEvent);
        }
      };
      _socket?.listen((RawSocketEvent e) {
        switch (e) {
          case RawSocketEvent.read:
            final d = _socket?.receive();
            if (d != null) {
              if (config.dtlsUse) {
                _dtlsConnection?.incoming(d.data);
              } else {
                processFrame(d.data);
              }
            }
            break;
          case RawSocketEvent.closed:
            close();
        }
      });
      if (config.dtlsUse) {
        _dtlsConnection?.received.listen(processFrame);
      }
    } on SocketException catch (e) {
      _log!.error(
          'CoapNetworkUDP Recieve - severe error - socket exception : $e');
    } on Exception catch (e) {
      _log!.error(
          'CoapNetworkUDP Recieve - severe error - unknown exception: $e');
    }
  }

  @override
  Future<void> bind() async {
    if (_bound) {
      return;
    }
    try {
      // Use a port of 0 here as we are a client, this will generate
      // a random source port.
      final bindAddress = address!.bind;
      _log!.info(
          'CoapNetworkUDP - binding to $bindAddress (dtls=${config.dtlsUse})');
      _socket = await RawDatagramSocket.bind(bindAddress, 0);
      if (config.dtlsUse) {
        _dtlsConnection = DtlsClientConnection(
            context: DtlsClientContext(
              verify: config.dtlsVerify,
              withTrustedRoots: config.dtlsWithTrustedRoots,
              ciphers: config.dtlsCiphers,
            ),
            hostname: address!.address.host);
      }
      receive();
      if (config.dtlsUse) {
        _dtlsConnection?.outgoing
            .listen((d) => _socket?.send(d, address!.address, port!));
        await _dtlsConnection?.connect().timeout(Duration(seconds: 10),
            onTimeout: () => throw HandshakeException(
                'Establishing dtls connection timed out'));
      }
      _bound = true;
    } on SocketException catch (e) {
      _log!.error('CoapNetworkUDP Recieve - severe error - socket exception '
          'failed to bind, address ${address!.address.host}, '
          'port $port with exception $e: $e');
    } on Exception catch (e) {
      _log!.error('CoapNetworkUDP - severe error - Failed to bind, '
          'address ${address!.address.host}, port $port with exception $e');
    }
  }

  @override
  void close() {
    _log!.info(
        'Network UDP - closing ${address!.address.host}, port $port (dtls=${config.dtlsUse})');
    _socket?.close();
    _data.close();
  }

  /// Equality, deemed to be equal if the address an port are the same
  @override
  bool operator ==(dynamic other) {
    if (other is CoapNetworkUDP) {
      if (other.port == port &&
          other.address == address &&
          other.namespace == namespace &&
          other.config.dtlsUse == config.dtlsUse) {
        return true;
      }
    }
    return false;
  }

  // Hash code
  @override
  int get hashCode {
    var result = 17;
    result = 37 * result + port.hashCode;
    result = 37 * result + address.hashCode;
    result = 37 * result + namespace.hashCode;
    return result;
  }
}
