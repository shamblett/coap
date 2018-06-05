/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

class CoapDataReceivedEvent {
  CoapDataReceivedEvent(this.data, this.endpoint);

  typed.Uint8Buffer data;
  InternetAddress endpoint;
}

/// Represents a channel where bytes data can flow through.
abstract class CoapIChannel extends Object with events.EventEmitter {
  /// Gets the local endpoint of this channel.
  InternetAddress localEndPoint;

  /// Starts this channel.
  void start();

  /// Stops this channel.
  void stop();

  /// Sends data through this channel. This method should be non-blocking.
  void send(typed.Uint8Buffer data, InternetAddress ep);

  /// Receives data, returns null if none
  typed.Uint8Buffer receive();

}
