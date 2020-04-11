/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/04/2017
 * Copyright :  S.Hamblett
 */
import 'package:coap/coap.dart';
import 'package:coap/config/coap_config_all.dart';
import 'package:coap/config/coap_config_default.dart';
import 'package:coap/config/coap_config_logging.dart';
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
      expect(CoapMediaType.name(unknownType), 'unknown/200');
      expect(CoapMediaType.fileExtension(unknownType), 'unknown/200');
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
      accepted = null;
      expect(
          CoapMediaType.negotiationContent(
              defaultContentType, supported, accepted),
          defaultContentType);
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
        CoapMediaType.textXml,
        CoapMediaType.applicationXml,
        CoapMediaType.applicationRdfXml,
        CoapMediaType.applicationSoapXml,
        CoapMediaType.applicationAtomXml,
        CoapMediaType.applicationXmppXml
      ]);
    });
  });

  group('Configuration', () {
    test('All', () {
      final DefaultCoapConfig conf = CoapConfigAll();
      conf.spec = CoapDraft18();
      expect(conf.version, 'RFC7252');
      expect(conf.defaultPort, 1);
      expect(conf.defaultSecurePort, 2);
      expect(conf.httpPort, 3);
      expect(conf.ackTimeout, 4);
      expect(conf.ackRandomFactor, 5.0);
      expect(conf.ackTimeoutScale, 6.0);
      expect(conf.maxRetransmit, 7);
      expect(conf.maxMessageSize, 8);
      expect(conf.defaultBlockSize, 9);
      expect(conf.blockwiseStatusLifetime, 10);
      expect(conf.useRandomIDStart, isFalse);
      expect(conf.useRandomTokenStart, isFalse);
      expect(conf.notificationMaxAge, 11);
      expect(conf.notificationCheckIntervalTime, 12);
      expect(conf.notificationCheckIntervalCount, 13);
      expect(conf.notificationReregistrationBackoff, 14);
      expect(conf.cropRotationPeriod, 15);
      expect(conf.exchangeLifetime, 16);
      expect(conf.markAndSweepInterval, 17);
      expect(conf.channelReceivePacketSize, 18);
      //TODO expect(conf.deduplicator,'');
      expect(conf.logTarget, 'console');
      expect(conf.logError, false);
      expect(conf.logInfo, true);
      expect(conf.logWarn, true);
      expect(conf.logDebug, true);
    });

    test('Default', () {
      final DefaultCoapConfig conf = CoapConfigDefault();
      conf.spec = CoapDraft18();
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
      expect(conf.useRandomTokenStart, isTrue);
      expect(conf.notificationMaxAge, 128 * 1000);
      expect(conf.notificationCheckIntervalTime, 24 * 60 * 60 * 1000);
      expect(conf.notificationCheckIntervalCount, 100);
      expect(conf.notificationReregistrationBackoff, 2000);
      expect(conf.cropRotationPeriod, 2000);
      expect(conf.exchangeLifetime, 247 * 1000);
      expect(conf.markAndSweepInterval, 10000);
      expect(conf.channelReceivePacketSize, 2048);
      //TODO expect(conf.deduplicator,'');
      expect(conf.logTarget, 'none');
      expect(conf.logError, true);
      expect(conf.logInfo, false);
      expect(conf.logWarn, false);
      expect(conf.logDebug, false);
    });

    test('Instance', () {
      final conf = CoapConfigDefault();
      expect(conf == DefaultCoapConfig.inst, isTrue);
    });
  });

  group('Logging', () {
    test('Null', () {
      final logmanager = CoapLogManager('none');
      final logger = logmanager.logger;
      expect(logger.isDebugEnabled(), isFalse);
      expect(logger.isErrorEnabled(), isFalse);
      expect(logger.isInfoEnabled(), isFalse);
      expect(logger.isWarnEnabled(), isFalse);
      logger.warn('Warning message');
      logger.info('Information message');
      logger.error('Error message');
      logger.debug('Debug message');
      logmanager.destroy();
    });

    test('Console', () {
      final conf = CoapConfigLogging();
      expect(conf.logTarget, 'console');
      final logmanager = CoapLogManager('console');
      final logger = logmanager.logger;
      // Add a string appender to test correct log strings
      expect(logger.isDebugEnabled(), isTrue);
      expect(logger.isErrorEnabled(), isTrue);
      expect(logger.isInfoEnabled(), isTrue);
      expect(logger.isWarnEnabled(), isTrue);
      logger.warn('Warning message');
      expect(logger.lastMessage.contains('Warning message'), isTrue);
      logger.info('Information message');
      expect(logger.lastMessage.contains('Information message'), isTrue);
      logger.error('Error message');
      expect(logger.lastMessage.contains('Error message'), isTrue);
      logger.debug('Debug message');
      expect(logger.lastMessage.contains('Debug message'), isTrue);
      logmanager.destroy();
    });
  });
}
