/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

class CoapRawData {
  typed.Uint8Buffer data;
  InternetAddress endPoint;
}

/// Channel via UDP protocol.
class CoapUDPChannel implements CoapIChannel {
  /// Default size of buffer for receiving packet.
  static const int defaultReceivePacketSize = 4096;

  /// Initializes a UDP channel with a random port.
  CoapUDPChannel() {
    _port = 0;
  }

  /// Initializes a UDP channel with the given port, both on IPv4 and IPv6.
  CoapUDPChannel.withPort(this._port);

  /// Initializes a UDP channel with the specific endpoint.
  CoapUDPChannel.withEndpoint(this._localEp);

  int receiveBufferSize;
  int sendBufferSize;
  int receivePacketSize = defaultReceivePacketSize;
  int _port;
  InternetAddress _localEp;

  InternetAddress get localEp =>
      _localEp == null ? InternetAddress.ANY_IP_V6 : _socket.socket.address;
  CoapNetworkUDP _socket;
  CoapNetworkUDP _socketBackup;
  int _running;
  int _writing;
  Queue<CoapRawData> _sendingQueue = new Queue<CoapRawData>();

  void dataReceived(events.Event event) {}
}
