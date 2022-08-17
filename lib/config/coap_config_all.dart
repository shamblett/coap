// GENERATED CODE, do not edit this file.

import 'package:coap/coap.dart';

/// Configuration loading class. The config file itself is a YAML
/// file. The configuration items below are marked as optional to allow
/// the config file to contain only those entries that override the defaults.
/// The file can't be empty, so version must as a minimum be present.
class CoapConfigAll extends DefaultCoapConfig {
  @override
  int get defaultPort => 1;

  @override
  int get defaultSecurePort => 2;

  @override
  int get httpPort => 3;

  @override
  int get ackTimeout => 4;

  @override
  double get ackRandomFactor => 5.0;

  @override
  double get ackTimeoutScale => 6.0;

  @override
  int get maxRetransmit => 7;

  @override
  int get maxMessageSize => 8;

  @override
  int get preferredBlockSize => 9;

  @override
  int get blockwiseStatusLifetime => 10;

  @override
  bool get useRandomIDStart => false;

  @override
  int get notificationMaxAge => 11;

  @override
  int get notificationCheckIntervalTime => 12;

  @override
  int get notificationCheckIntervalCount => 13;

  @override
  int get notificationReregistrationBackoff => 14;

  @override
  int get cropRotationPeriod => 15;

  @override
  int get exchangeLifetime => 16;

  @override
  int get markAndSweepInterval => 17;

  @override
  int get channelReceivePacketSize => 18;

  @override
  String get deduplicator => 'MarkAndSweep';

  @override
  bool get dtlsVerify => false;

  @override
  bool get dtlsWithTrustedRoots => false;
}
