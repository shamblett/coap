/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 22/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Represents a channel where bytes data can flow through.
abstract class CoapIChannel extends Object with events.EventEmitter {
  /// Gets the local endpoint of this channel.
  InternetAddress localEndPoint;

  /// Occurs when some bytes are received in this channel.
  void dataReceived(events.Event event);

  /// Starts this channel.
  void start();

  /// Stops this channel.
  void stop();

  /// Sends data through this channel. This method should be non-blocking.
  void send(typed.Uint8Buffer data, Uri ep);
}
