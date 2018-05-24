/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Channel via UDP protocol.
class CoapUDPChannel extends CoapIChannel {
  /// Initializes a UDP channel with a random port.
  CoapUDPChannel() : this.withPort(0);

  /// Initializes a UDP channel with the given port, both on IPv4 and IPv6.
  CoapUDPChannel.withPort(this._port);

  /// Initializes a UDP channel with the specific endpoint.
  CoapUDPChannel.withEndpoint(this._localEp);

  int _port;
  InternetAddress _localEp;

  InternetAddress get localEp =>
      _localEp == null ? InternetAddress.ANY_IP_V6 : _socket.socket.address;
  CoapNetworkUDP _socket;

  InternetAddress get localEndPoint => localEp;

  set localEndPoint(InternetAddress address) => _localEp = address;

  void start() {
    _socket.port = _port;
    _socket.address = localEp;
    _socket.bind();
  }

  void stop() {
    _socket.close();
  }

  void send(typed.Uint8Buffer data) {
    _socket.send(data);
  }

  typed.Uint8Buffer receive() {
    return _socket.receive();
  }
}
