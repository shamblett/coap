/*
 * Package : Coap
 * Author : Sorunome <mail@sorunome.de>,
 *          Jan Romann <jan.romann@uni-bremen.de>
 * Date   : 05/09/2022
 * Copyright :  Jan Romann
 */

part of coap;

/// DTLS network using OpenSSL
class CoapNetworkOpenSSL implements CoapINetwork {
  /// Initialize with an [address] and a [port].
  ///
  /// This [CoapINetwork] can be configured to be used [withTrustedRoots] and
  /// to [verify] certificate chains. You can also indicate a list of [ciphers],
  /// see the [OpenSSL documentation] for more information on this.
  ///
  /// [OpenSSL documentation]: https://www.openssl.org/docs/man1.1.1/man1/ciphers.html
  CoapNetworkOpenSSL(
    this.address,
    this.port, {
    String namespace = '',
    String? ciphers,
    required bool verify,
    required bool withTrustedRoots,
  })  : _eventBus = CoapEventBus(namespace: namespace),
        _ciphers = ciphers,
        _verify = verify,
        _withTrustedRoots = withTrustedRoots;

  final CoapEventBus _eventBus;

  void _processFrame(Uint8List frame) {
    final buff = typed.Uint8Buffer();
    if (frame.isNotEmpty) {
      buff.addAll(frame.toList());
      final rxEvent = CoapDataReceivedEvent(buff, address);
      _eventBus.fire(rxEvent);
    }
  }

  dtls.DtlsClientConnection? _dtlsConnection;

  RawDatagramSocket? _socket;

  RawDatagramSocket? get socket => _socket;

  final bool _verify;

  final String? _ciphers;

  final bool _withTrustedRoots;

  @override
  final CoapInternetAddress address;

  @override
  final int port;

  @override
  String get namespace => _eventBus.namespace;

  bool _bound = false;

  @override
  Future<int> send(typed.Uint8Buffer data,
      [CoapInternetAddress? address]) async {
    // FIXME: There is currently no way for reconnecting if the connection has
    //        been lost in the meantime

    final bytes = Uint8List.view(data.buffer, data.offsetInBytes, data.length);

    // TODO: The send method does not return the number of bytes written at
    //       the moment.
    _dtlsConnection?.send(bytes);
    return -1;
  }

  @override
  void receive() {
    _socket?.listen((event) {
      switch (event) {
        case RawSocketEvent.read:
          final datagram = _socket?.receive();

          if (datagram == null) {
            return;
          }

          _dtlsConnection?.incoming(datagram.data);
          break;
        default:
          break;
      }
    });
    _dtlsConnection?.received.listen(_processFrame);
  }

  @override
  Future<void> bind() async {
    if (_bound) {
      return;
    }
    // Use a port of 0 here as we are a client, this will generate
    // a random source port.
    final bindAddress = address.bind;
    _socket = await RawDatagramSocket.bind(bindAddress, 0);
    _dtlsConnection = dtls.DtlsClientConnection(
        context: dtls.DtlsClientContext(
          verify: _verify,
          withTrustedRoots: _withTrustedRoots,
          ciphers: _ciphers,
        ),
        hostname: address.address.host);
    receive();
    _dtlsConnection?.outgoing
        .listen((d) => _socket?.send(d, address.address, port));
    await _dtlsConnection
        ?.connect()
        .timeout(Duration(seconds: 10), onTimeout: _handleTimeout);
    _bound = true;
  }

  void _handleTimeout() {
    close();
    throw HandshakeException('Establishing dtls connection timed out');
  }

  @override
  void close() {
    _socket?.close();
    _dtlsConnection?.free();
    _bound = false;
  }
}
