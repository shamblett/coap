/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/04/2017
 * Copyright :  S.Hamblett
 */
import 'package:coap/coap.dart';
import 'package:coap/config/coap_config_all.dart';
import 'package:coap/config/coap_config_default.dart';
import 'package:test/test.dart';

void main() {
  group('Media types', () {
    test('Properties', () {
      const type = CoapMediaType.applicationJson;
      expect(CoapMediaType.name(type), 'application/json');
      expect(CoapMediaType.fileExtension(type), 'json');
      expect(CoapMediaType.isPrintable(type), true);
      expect(CoapMediaType.isImage(type), false);

      const unknownType = 200;
      expect(CoapMediaType.name(unknownType), 'application/octet-stream');
      expect(CoapMediaType.fileExtension(unknownType), 'undefined');
      expect(CoapMediaType.isPrintable(unknownType), false);
      expect(CoapMediaType.isImage(unknownType), false);
    });

    test('Negotiation Content', () {
      const defaultContentType = 10;
      final supported = <int>[11, 5];
      var accepted = <CoapOption>[];
      final opt1 = CoapOption.createVal(optionTypeMaxAge, 10);
      final opt2 = CoapOption.createVal(optionTypeContentFormat, 5);
      accepted.add(opt1);
      accepted.add(opt2);
      expect(
          CoapMediaType.negotiationContent(
              defaultContentType, supported, accepted),
          5);
      opt2.intValue = 67;
      expect(
          CoapMediaType.negotiationContent(
              defaultContentType, supported, accepted),
          CoapMediaType.undefined);
    });

    test('Parse', () {
      var res = CoapMediaType.parse(null);
      expect(res, CoapMediaType.undefined);

      res = CoapMediaType.parse('application/xml');
      expect(res, CoapMediaType.applicationXml);
    });

    test('Parse wild card', () {
      var res = CoapMediaType.parseWildcard(null);
      expect(res, isNull);

      res = CoapMediaType.parseWildcard('xml*');
      expect(res, <int>[
        CoapMediaType.applicationXml,
        CoapMediaType.applicationSenmlXml,
        CoapMediaType.applicationSensmlXml,
      ]);
    });
  });

  group('Configuration', () {
    test('All', () {
      final DefaultCoapConfig conf = CoapConfigAll();
      expect(conf.version, 'RFC7252');
      expect(conf.defaultPort, 1);
      expect(conf.defaultSecurePort, 2);
      expect(conf.httpPort, 3);
      expect(conf.defaultTimeout, 4);
      expect(conf.ackTimeout, 5);
      expect(conf.ackRandomFactor, 6.0);
      expect(conf.ackTimeoutScale, 7.0);
      expect(conf.maxRetransmit, 8);
      expect(conf.maxMessageSize, 9);
      expect(conf.defaultBlockSize, 10);
      expect(conf.blockwiseStatusLifetime, 11);
      expect(conf.useRandomIDStart, isFalse);
      expect(conf.notificationMaxAge, 12);
      expect(conf.notificationCheckIntervalTime, 13);
      expect(conf.notificationCheckIntervalCount, 14);
      expect(conf.notificationReregistrationBackoff, 15);
      expect(conf.cropRotationPeriod, 16);
      expect(conf.exchangeLifetime, 17);
      expect(conf.markAndSweepInterval, 18);
      expect(conf.channelReceivePacketSize, 19);
      expect(conf.deduplicator, 'MarkAndSweep');
    });

    test('Default', () {
      final DefaultCoapConfig conf = CoapConfigDefault();
      expect(conf.version, 'RFC7252');
      expect(conf.defaultPort, CoapConstants.defaultPort);
      expect(conf.defaultSecurePort, CoapConstants.defaultSecurePort);
      expect(conf.httpPort, 8080);
      expect(conf.ackTimeout, CoapConstants.ackTimeout);
      expect(conf.ackRandomFactor, CoapConstants.ackRandomFactor);
      expect(conf.ackTimeoutScale, 2.0);
      expect(conf.maxRetransmit, CoapConstants.maxRetransmit);
      expect(conf.maxMessageSize, 1024);
      expect(conf.defaultBlockSize, CoapConstants.defaultBlockSize);
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
