/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

// ignore_for_file: public_member_api_docs

/// Configuration loading class. The config file itself is a YAML
/// file. The configuration items below are marked as optional to allow
/// the config file to contain only those entries that override the defaults.
/// The file can't be empty, so version must as a minimum be present.
class CoapConfig extends config.Configuration {
  /// Construction
  CoapConfig(File file) : super.fromFile(file) {
    _config = this;
  }

  static CoapConfig _config;

  /// Instance
  static CoapConfig get inst => _config;

  /// Protocol options

  /// The version of the CoAP protocol.
  String version = 'RFC7252';

  @config.optionalConfiguration
  CoapISpec spec;

  /// The default CoAP port for normal CoAP communication (not secure).
  @config.optionalConfiguration
  int defaultPort = CoapConstants.defaultPort;

  /// The default CoAP port for secure CoAP communication (coaps).
  @config.optionalConfiguration
  int defaultSecurePort = CoapConstants.defaultSecurePort;

  /// The port which HTTP proxy is on.
  @config.optionalConfiguration
  int httpPort = 8080;

  /// The initial time (ms) for a CoAP message
  @config.optionalConfiguration
  int ackTimeout = CoapConstants.ackTimeout;

  /// The initial timeout is set
  /// to a random number between RESPONSE_TIMEOUT and (RESPONSE_TIMEOUT *
  /// RESPONSE_RANDOM_FACTOR)
  ///
  @config.optionalConfiguration
  double ackRandomFactor = CoapConstants.ackRandomFactor;

  @config.optionalConfiguration
  double ackTimeoutScale = 2.0;

  /// The max time that a message would be retransmitted
  @config.optionalConfiguration
  int maxRetransmit = CoapConstants.maxRetransmit;

  @config.optionalConfiguration
  int maxMessageSize = 1024;

  /// The default preferred size of block in blockwise transfer.
  @config.optionalConfiguration
  int defaultBlockSize = CoapConstants.defaultBlockSize;

  @config.optionalConfiguration
  int blockwiseStatusLifetime = 10 * 60 * 1000; // ms
  @config.optionalConfiguration
  bool useRandomIDStart = true;
  @config.optionalConfiguration
  bool useRandomTokenStart = true;

  @config.optionalConfiguration
  int notificationMaxAge = 128 * 1000; // ms
  @config.optionalConfiguration
  int notificationCheckIntervalTime = 24 * 60 * 60 * 1000; // ms
  @config.optionalConfiguration
  int notificationCheckIntervalCount = 100; // ms
  @config.optionalConfiguration
  int notificationReregistrationBackoff = 2000; // ms

  String deduplicator = CoapDeduplicatorFactory.markAndSweepDeduplicator;
  @config.optionalConfiguration
  int cropRotationPeriod = 2000; // ms
  @config.optionalConfiguration
  int exchangeLifetime = 247 * 1000; // ms
  @config.optionalConfiguration
  int markAndSweepInterval = 10 * 1000; // ms
  @config.optionalConfiguration
  int channelReceivePacketSize = 2048;

  /// Logging options

  /// Log to null, console or file
  @config.optionalConfiguration
  String logTarget = 'none';

  /// Log level options
  @config.optionalConfiguration
  bool logError = true;
  @config.optionalConfiguration
  bool logWarn = false;
  @config.optionalConfiguration
  bool logDebug = false;
  @config.optionalConfiguration
  bool logInfo = false;
}
