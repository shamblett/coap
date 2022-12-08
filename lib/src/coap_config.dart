/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 27/04/2017
 * Copyright :  S.Hamblett
 */

import 'package:dart_tinydtls/dart_tinydtls.dart';
import 'dart:typed_data';

import 'coap_constants.dart';
import 'deduplication/deduplicator_factory.dart';

enum DtlsBackend {
  OpenSsl,
  TinyDtls,
}

/// Configuration loading class. The config file itself is a YAML
/// file. The configuration items below are marked as optional to allow
/// the config file to contain only those entries that override the defaults.
/// The file can't be empty, so version must as a minimum be present.
abstract class DefaultCoapConfig {
  /// Protocol options

  /// The default CoAP port for normal CoAP communication (not secure).
  int defaultPort = CoapConstants.defaultPort;

  /// The default CoAP port for secure CoAP communication (coaps).
  int defaultSecurePort = CoapConstants.defaultSecurePort;

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

  /// The preferred size of block in blockwise transfer.

  int get preferredBlockSize => CoapConstants.preferredBlockSize;

  int get blockwiseStatusLifetime => 10 * 60 * 1000; // ms

  bool get useRandomIDStart => true;

  bool get poolUdpConnectionsByClient => false;

  int get notificationMaxAge => 128 * 1000; // ms

  int get notificationCheckIntervalTime => 24 * 60 * 60 * 1000; // ms

  int get notificationCheckIntervalCount => 100; // ms

  int get notificationReregistrationBackoff => 2000; // ms

  String get deduplicator => DeduplicatorFactory.markAndSweepDeduplicator;

  int get cropRotationPeriod => 2000; // ms

  int get exchangeLifetime => 247 * 1000; // ms

  int get markAndSweepInterval => 10 * 1000; // ms

  int get channelReceivePacketSize => 2048;

  /// Indicates which [DtlsBackend] a new [CoapClient] should use.
  DtlsBackend? get dtlsBackend => null;

  /// Custom [TinyDTLS] instance that can be registered if tinyDTLS
  /// should not be available at the default locations.
  TinyDTLS? get tinyDtlsInstance => null;

  /// Whether OpenSSL bindings via the [dtls] package should be used for CoAPS.
  bool get dtlsUseOpenSSL => false;

  /// Whether certificates should be verified by OpenSSL.
  bool get dtlsVerify => true;

  /// Whether OpenSSL should be used with trusted Root Certificates.
  bool get dtlsWithTrustedRoots => true;

  /// List of custom root certificates to use with OpenSSL.
  List<Uint8List> get rootCertificates => const [];

  /// Can be used to specify the Ciphers that should be used by OpenSSL.
  String? get dtlsCiphers => null;
}
