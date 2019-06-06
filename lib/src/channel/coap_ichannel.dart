/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Data received Event
class CoapDataReceivedEvent {
  /// Construction
  CoapDataReceivedEvent(this.data, this.address);

  /// The data
  typed.Uint8Buffer data;

  /// The address
  InternetAddress address;
}

/// Represents a channel where bytes data can flow through.
abstract class CoapIChannel {
  /// Gets the address of this channel.
  InternetAddress address;

  /// Port
  int port;

  /// Starts this channel.
  void start();

  /// Stops this channel.
  void stop();

  /// Sends data through this channel. This method should be non-blocking.
  void send(typed.Uint8Buffer data, InternetAddress address);

  /// Receives data, returns null if none
  void receive();
}
