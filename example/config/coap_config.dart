// GENERATED CODE, do not edit this file.

import 'package:coap/coap.dart';

/// Configuration loading class. The config file itself is a YAML
/// file. The configuration items below are marked as optional to allow
/// the config file to contain only those entries that override the defaults.
/// The file can't be empty, so version must as a minimum be present.
class CoapConfig extends DefaultCoapConfig {
  @override
  int get defaultPort => 5683;

  @override
  int get defaultSecurePort => 5684;

  @override
  int get httpPort => 8080;

  @override
  int get ackTimeout => 3000;

  @override
  double get ackRandomFactor => 1.5;

  @override
  double get ackTimeoutScale => 2.0;

  @override
  int get maxRetransmit => 8;

  @override
  int get maxMessageSize => 1024;

  @override
  int get preferredBlockSize => 512;

  @override
  int get blockwiseStatusLifetime => 60000;

  @override
  bool get useRandomIDStart => true;

  @override
  int get notificationMaxAge => 128000;

  @override
  int get notificationCheckIntervalTime => 86400000;

  @override
  int get notificationCheckIntervalCount => 100;

  @override
  int get notificationReregistrationBackoff => 2000;

  @override
  int get cropRotationPeriod => 2000;

  @override
  int get exchangeLifetime => 1247000;

  @override
  int get markAndSweepInterval => 10000;

  @override
  int get channelReceivePacketSize => 2048;

  @override
  String get deduplicator => 'MarkAndSweep';
}
