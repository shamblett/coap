/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/04/2017
 * Copyright :  S.Hamblett
 */
import 'package:coap/coap.dart';
import 'package:test/test.dart';

void main() {
  group('Media types', () {
    test('Properties', () {
      const type = CoapMediaType.applicationJson;
      expect(type.mimeType, 'application/json');
      expect(type.isPrintable, true);
      expect(type.isImage, false);

      const unknownType = 200;
      expect(CoapMediaType.fromIntValue(unknownType), null);
    });

    test('Parse', () {
      final res = CoapMediaType.parse('application/xml');
      expect(res, CoapMediaType.applicationXml);
    });
  });

  group('Configuration', () {
    test('All', () {
      final DefaultCoapConfig conf = CoapConfigAll();
      expect(conf.defaultPort, 1);
      expect(conf.defaultSecurePort, 2);
      expect(conf.httpPort, 3);
      expect(conf.ackTimeout, 4);
      expect(conf.ackRandomFactor, 5.0);
      expect(conf.ackTimeoutScale, 6.0);
      expect(conf.maxRetransmit, 7);
      expect(conf.maxMessageSize, 8);
      expect(conf.preferredBlockSize, 9);
      expect(conf.blockwiseStatusLifetime, 10);
      expect(conf.useRandomIDStart, isFalse);
      expect(conf.notificationMaxAge, 11);
      expect(conf.notificationCheckIntervalTime, 12);
      expect(conf.notificationCheckIntervalCount, 13);
      expect(conf.notificationReregistrationBackoff, 14);
      expect(conf.cropRotationPeriod, 15);
      expect(conf.exchangeLifetime, 16);
      expect(conf.markAndSweepInterval, 17);
      expect(conf.channelReceivePacketSize, 18);
      expect(conf.deduplicator, 'MarkAndSweep');
    });

    test('Default', () {
      final DefaultCoapConfig conf = CoapConfigDefault();
      expect(conf.defaultPort, CoapConstants.defaultPort);
      expect(conf.defaultSecurePort, CoapConstants.defaultSecurePort);
      expect(conf.httpPort, 8080);
      expect(conf.ackTimeout, CoapConstants.ackTimeout);
      expect(conf.ackRandomFactor, CoapConstants.ackRandomFactor);
      expect(conf.ackTimeoutScale, 2.0);
      expect(conf.maxRetransmit, CoapConstants.maxRetransmit);
      expect(conf.maxMessageSize, 1024);
      expect(conf.preferredBlockSize, CoapConstants.preferredBlockSize);
      expect(conf.blockwiseStatusLifetime, 10 * 60 * 1000);
      expect(conf.useRandomIDStart, isTrue);
      expect(conf.notificationMaxAge, 128 * 1000);
      expect(conf.notificationCheckIntervalTime, 24 * 60 * 60 * 1000);
      expect(conf.notificationCheckIntervalCount, 100);
      expect(conf.notificationReregistrationBackoff, 2000);
      expect(conf.cropRotationPeriod, 2000);
      expect(conf.exchangeLifetime, 247 * 1000);
      expect(conf.markAndSweepInterval, 10000);
      expect(conf.channelReceivePacketSize, 2048);
      expect(conf.deduplicator, 'MarkAndSweep');
    });
  });
}
