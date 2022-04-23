/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Configuration loading class. The config file itself is a YAML
/// file. The configuration items below are marked as optional to allow
/// the config file to contain only those entries that override the defaults.
/// The file can't be empty, so version must as a minimum be present.
abstract class DefaultCoapConfig {
  /// Protocol options

  /// The version of the CoAP protocol.
  String get version => 'RFC7252';

  /// The CoAP specification derived from the protocol version.
  CoapISpec get spec {
    switch (version) {
      case 'RFC7252':
        return CoapRfc7252();
      default:
        throw ArgumentError("Invalid or missing version");
    }
  }

  /// The default CoAP port for normal CoAP communication (not secure).
  int defaultPort = CoapConstants.defaultPort;

  /// The default CoAP port for secure CoAP communication (coaps).
  int defaultSecurePort = CoapConstants.defaultSecurePort;

  /// The port which HTTP proxy is on.
  int get httpPort => 8080;

  /// Default request timeout
  int get defaultTimeout => CoapConstants.defaultTimeout;

  /// The initial time (ms) for a CoAP message
  int get ackTimeout => CoapConstants.ackTimeout;

  /// The initial timeout is set
  /// to a random number between RESPONSE_TIMEOUT and (RESPONSE_TIMEOUT *
  /// RESPONSE_RANDOM_FACTOR)
  ///
  double get ackRandomFactor => CoapConstants.ackRandomFactor;

  double get ackTimeoutScale => 2.0;

  /// The max time that a message would be retransmitted

  int get maxRetransmit => CoapConstants.maxRetransmit;

  int get maxMessageSize => 1024;

  /// The preferred size of block in blockwise transfer.

  int get preferredBlockSize => CoapConstants.preferredBlockSize;

  int get blockwiseStatusLifetime => 10 * 60 * 1000; // ms

  bool get useRandomIDStart => true;

  bool get poolUdpConnectionsByClient => false;

  int get notificationMaxAge => 128 * 1000; // ms

  int get notificationCheckIntervalTime => 24 * 60 * 60 * 1000; // ms

  int get notificationCheckIntervalCount => 100; // ms

  int get notificationReregistrationBackoff => 2000; // ms

  String get deduplicator => CoapDeduplicatorFactory.markAndSweepDeduplicator;

  int get cropRotationPeriod => 2000; // ms

  int get exchangeLifetime => 247 * 1000; // ms

  int get markAndSweepInterval => 10 * 1000; // ms

  int get channelReceivePacketSize => 2048;
}
