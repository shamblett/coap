/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Package wide constants
class CoapConstants {
  ///
  /// RFC 7252 CoAP version.
  ///
  static const int version = 0x01;

  ///
  /// The CoAP URI scheme.
  ///
  static const String uriScheme = 'coap';

  ///
  /// The CoAPS URI scheme.
  ///
  static const String secureUriScheme = 'coaps';

  ///
  /// The default CoAP port for normal CoAP communication (not secure).
  ///
  static const int defaultPort = 5683;

  ///
  /// The default CoAP port for secure CoAP communication (coaps).
  ///
  static const int defaultSecurePort = 5684;

  ///
  /// The initial time (ms) for a CoAP message
  ///
  static const int ackTimeout = 3000;

  ///
  /// The initial timeout is set
  /// to a random number between RESPONSE_TIMEOUT and (RESPONSE_TIMEOUT *
  /// RESPONSE_RANDOM_FACTOR)
  ///
  static const double ackRandomFactor = 1.5;

  ///
  /// The max times that a message would be retransmitted
  ///
  static const int maxRetransmit = 8;

  ///
  /// Default block size used for block-wise transfers
  ///
  static const int defaultBlockSize = 512;

  ///
  /// Message cache size
  ///
  static const int messageCacheSize = 32;

  ///
  /// Receive bufefr size
  /// ///
  static const int receiveBufferSize = 4096;

  ///
  /// Overall request timeout
  ///
  static const int defaultOverallTimeout = 100000;

  ///
  /// Default URI for well known resource
  ///
  static const String defaultWellKnownURI = '/.well-known/core';

  ///
  /// Token length
  ///
  static const int tokenLength = 8;

  ///
  /// Max age
  ///
  static const int defaultMaxAge = 60;

  ///
  /// The number of notifications until a CON notification will be used.
  ///
  static const int observingRefreshInterval = 10;

  ///
  /// Empty token
  ///
  static typed.Uint8Buffer emptyToken = typed.Uint8Buffer(1);

  ///
  /// The lowest value of a request code.
  ///
  static const int requestCodeLowerBound = 1;

  ///
  /// The highest value of a request code.
  ///
  static const int requestCodeUpperBound = 31;

  ///
  /// The lowest value of a response code.
  ///
  static const int responseCodeLowerBound = 64;

  ///
  /// The highest value of a response code.
  ///
  static const int responseCodeUpperBound = 191;
}
