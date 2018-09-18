/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Channel via UDP protocol.
class CoapUDPChannel extends CoapIChannel {
  /// Intialize with a specific address and port
  CoapUDPChannel(this._address, this._port) {
    _socket = new CoapNetworkUDP(address, port);
  }

  int _port;

  int get port => _port;
  InternetAddress _address;

  InternetAddress get address =>
      _address == null ? InternetAddress.anyIPv6 : _address;
  CoapNetworkUDP _socket;

  void start() {
    _socket.port = _port;
    _socket.address = _address;
    _socket.bind();
  }

  void stop() {
    _socket.close();
  }

  void send(typed.Uint8Buffer data, [InternetAddress sendAddress]) {
    if (sendAddress != null) {
      final CoapNetworkUDP socket =
          CoapNetworkManagement.getNetwork(sendAddress, _port);
      if (socket?.socket != null) {
        socket.send(data);
      }
    } else {
      if (_socket?.socket != null) {
        _socket.send(data);
      }
    }
  }

  typed.Uint8Buffer receive() {
    final typed.Uint8Buffer buff = _socket.receive();
    final CoapDataReceivedEvent rxEvent =
        new CoapDataReceivedEvent(buff, _address);
    clientEventBus.fire(rxEvent);
    return buff;
  }
}
