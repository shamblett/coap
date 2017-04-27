/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

class CoapConfig extends config.ConfigurationItem {
  CoapConfig(String filename) : super.fromFile(filename);

  /// The version of the CoAP protocol.
  @config.optionalConfiguration
  String version = "RFC7252";

  /// The default CoAP port for normal CoAP communication (not secure).
  int defaultPort = CoapConstants.defaultPort;

  /// The default CoAP port for secure CoAP communication (coaps).
  int defaultSecurePort = CoapConstants.defaultSecurePort;

  /// The port which HTTP proxy is on.
  int httpPort = 8080;

  /// The initial time (ms) for a CoAP message
  int ackTimeout = CoapConstants.ackTimeout;

  /// The initial timeout is set
  /// to a random number between RESPONSE_TIMEOUT and (RESPONSE_TIMEOUT *
  /// RESPONSE_RANDOM_FACTOR)
  ///
  double AckRandomFactor = CoapConstants.ackRandomFactor;

  double AckTimeoutScale = 2.0;

  /// The max time that a message would be retransmitted
  int MaxRetransmit = CoapConstants.maxRetransmit;

  int MaxMessageSize = 1024;

  /// The default preferred size of block in blockwise transfer.
  int DefaultBlockSize = CoapConstants.defaultBlockSize;

  int blockwiseStatusLifetime = 10 * 60 * 1000; // ms
  bool useRandomIDStart = true;
  bool useRandomTokenStart = true;

  int notificationMaxAge = 128 * 1000; // ms
  int notificationCheckIntervalTime = 24 * 60 * 60 * 1000; // ms
  int notificationCheckIntervalCount = 100; // ms
  int notificationReregistrationBackoff = 2000; // ms

  //TODO string deduplicator = CoAP.Deduplication.DeduplicatorFactory.MarkAndSweepDeduplicator;
  int cropRotationPeriod = 2000; // ms
  int exchangeLifetime = 247 * 1000; // ms
  int markAndSweepInterval = 10 * 1000; // ms
  int channelReceivePacketSize = 2048;
}
