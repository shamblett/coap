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
  /// Instance
  static DefaultCoapConfig inst;

  /// Protocol options

  /// The version of the CoAP protocol.
  String get version => '';

  CoapISpec spec;

  /// The default CoAP port for normal CoAP communication (not secure).
  int defaultPort = CoapConstants.defaultPort;

  /// The default CoAP port for secure CoAP communication (coaps).
  int get defaultSecurePort => CoapConstants.defaultSecurePort;

  /// The port which HTTP proxy is on.
  int get httpPort => 8080;

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

  /// The default preferred size of block in blockwise transfer.

  int get defaultBlockSize => CoapConstants.defaultBlockSize;

  int get blockwiseStatusLifetime => 10 * 60 * 1000; // ms

  bool get useRandomIDStart => true;

  bool get useRandomTokenStart => true;

  int get notificationMaxAge => 128 * 1000; // ms

  int get notificationCheckIntervalTime => 24 * 60 * 60 * 1000; // ms

  int get notificationCheckIntervalCount => 100; // ms

  int get notificationReregistrationBackoff => 2000; // ms

  String get deduplicator => CoapDeduplicatorFactory.markAndSweepDeduplicator;

  int get cropRotationPeriod => 2000; // ms

  int get exchangeLifetime => 247 * 1000; // ms

  int get markAndSweepInterval => 10 * 1000; // ms

  int get channelReceivePacketSize => 2048;

  /// Logging options

  /// Log to null, console or file

  String get logTarget => 'none';

  /// Log level options

  bool get logError => true;

  bool get logWarn => false;

  bool get logDebug => false;

  bool get logInfo => false;
}
