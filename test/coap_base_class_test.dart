/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/04/2017
 * Copyright :  S.Hamblett
 */
import 'package:coap/coap.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'package:log4dart/log4dart_vm.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:io';

void main() {
  group("Options", () {
    final Utf8Encoder encoder = new Utf8Encoder();

    test('Raw', () {
      final typed.Uint8Buffer raw = new typed.Uint8Buffer(3);
      raw.addAll(encoder.convert("raw"));
      final CoapOption opt = CoapOption.createRaw(optionTypeContentType, raw);
      expect(opt.valueBytes, raw);
      expect(opt.type, optionTypeContentType);
    });

    test('IntValue', () {
      final int oneByteValue = 255;
      final int twoByteValue = oneByteValue + 1;
      final CoapOption opt1 = CoapOption.createVal(
          optionTypeContentType, oneByteValue);
      final CoapOption opt2 = CoapOption.createVal(
          optionTypeContentType, twoByteValue);
      expect(opt1.length, 1);
      expect(opt2.length, 2);
      expect(opt1.intValue, oneByteValue);
      expect(opt2.intValue, twoByteValue);
      expect(opt1.type, optionTypeContentType);
      expect(opt2.type, optionTypeContentType);
    });

    test('LongValue', () {
      final int fourByteValue = pow(2, 32) - 1;
      final int fiveByteValue = fourByteValue + 1;
      final CoapOption opt1 =
      CoapOption.createLongVal(optionTypeContentType, fourByteValue);
      final CoapOption opt2 =
      CoapOption.createLongVal(optionTypeContentType, fiveByteValue);
      expect(opt1.length, 4);
      expect(opt2.length, 5);
      expect(opt1.longValue, fourByteValue);
      expect(opt2.longValue, fiveByteValue);
      expect(opt1.type, optionTypeContentType);
      expect(opt2.type, optionTypeContentType);
    });

    test('String', () {
      final String s = "hello world";
      final CoapOption opt = CoapOption.createString(optionTypeContentType, s);
      expect(opt.length, 11);
      expect(s, opt.stringValue);
      expect(opt.type, optionTypeContentType);
    });

    test('Name', () {
      final CoapOption opt = CoapOption.create(optionTypeUriQuery);
      expect(opt.name, "Uri-Query");
    });

    test('Value', () {
      final CoapOption opt = CoapOption.createVal(optionTypeMaxAge, 10);
      expect(opt.value, 10);
      final CoapOption opt1 = CoapOption.createString(
          optionTypeUriQuery, "Hello");
      expect(opt1.value, "Hello");
      final CoapOption opt2 = CoapOption.create(optionTypeReserved);
      expect(opt2.value, isNull);
      final CoapOption opt3 = CoapOption.create(1000);
      expect(opt3.value, isNull);
    });

    test('Long value', () {
      final CoapOption opt = CoapOption.createLongVal(optionTypeMaxAge, 10);
      expect(opt.value, 10);
    });

    test('Is default', () {
      final CoapOption opt =
      CoapOption.createVal(optionTypeMaxAge, CoapConstants.defaultMaxAge);
      expect(opt.isDefault(), isTrue);
      final CoapOption opt1 = CoapOption.create(optionTypeToken);
      expect(opt1.isDefault(), isTrue);
      final CoapOption opt2 = CoapOption.create(optionTypeReserved);
      expect(opt2.isDefault(), isFalse);
    });

    test('To string', () {
      final CoapOption opt =
      CoapOption.createVal(optionTypeMaxAge, CoapConstants.defaultMaxAge);
      expect(opt.toString(), "Max-Age: 60");
    });

    test('Option format', () {
      expect(
          CoapOption.getFormatByType(optionTypeMaxAge), optionFormat.integer);
      expect(
          CoapOption.getFormatByType(optionTypeUriHost), optionFormat.string);
      expect(CoapOption.getFormatByType(optionTypeETag), optionFormat.opaque);
      expect(CoapOption.getFormatByType(1000), optionFormat.unknown);
    });

    test('Hash code', () {
      final CoapOption opt = CoapOption.createVal(optionTypeMaxAge, 10);
      expect(opt.hashCode, 45);
    });

    test('Equality', () {
      final int oneByteValue = 255;
      final int twoByteValue = 256;

      final CoapOption opt1 = CoapOption.createVal(
          optionTypeContentType, oneByteValue);
      final CoapOption opt2 = CoapOption.createVal(
          optionTypeContentType, twoByteValue);
      final CoapOption opt22 =
      CoapOption.createVal(optionTypeContentType, twoByteValue);

      expect(opt1 == opt2, isFalse);
      expect(opt2 == opt22, isTrue);
      expect(opt1 == null, isFalse);
    });

    test('Empty token', () {
      final CoapOption opt1 = CoapOption.create(optionTypeToken);
      final CoapOption opt2 = CoapOption.create(optionTypeToken);
      final CoapOption opt22 = CoapOption.createString(optionTypeToken, "full");

      expect(opt1 == opt2, isTrue);
      expect(opt2 == opt22, isFalse);
      expect(opt1.length, 0);
    });

    test('1 Byte token', () {
      final CoapOption opt1 = CoapOption.createVal(optionTypeToken, 0xCD);
      final CoapOption opt2 = CoapOption.createVal(optionTypeToken, 0xCD);
      final CoapOption opt22 = CoapOption.createVal(optionTypeToken, 0xCE);

      expect(opt1 == opt2, isTrue);
      expect(opt2 == opt22, isFalse);
      expect(opt1.length, 1);
    });

    test('2 Byte token', () {
      final CoapOption opt1 = CoapOption.createVal(optionTypeToken, 0xABCD);
      final CoapOption opt2 = CoapOption.createVal(optionTypeToken, 0xABCD);
      final CoapOption opt22 = CoapOption.createVal(optionTypeToken, 0xABCE);

      expect(opt1 == opt2, isTrue);
      expect(opt2 == opt22, isFalse);
      expect(opt1.length, 2);
    });

    test('4 Byte token', () {
      final CoapOption opt1 = CoapOption.createVal(optionTypeToken, 0x1234ABCD);
      final CoapOption opt2 = CoapOption.createVal(optionTypeToken, 0x1234ABCD);
      final CoapOption opt22 = CoapOption.createVal(
          optionTypeToken, 0x1234ABCE);

      expect(opt1 == opt2, isTrue);
      expect(opt2 == opt22, isFalse);
      expect(opt1.length, 4);
    });

    test('Set value', () {
      final CoapOption option = CoapOption.create(optionTypeReserved);

      option.valueBytes = new typed.Uint8Buffer(4);
      expect(option.length, 4);

      option.valueBytesList = [69, 152, 35, 55, 152, 116, 35, 152];
      expect(option.valueBytes, [69, 152, 35, 55, 152, 116, 35, 152]);
    });

    test('Set string value', () {
      final CoapOption option = CoapOption.create(optionTypeReserved);

      option.stringValue = "";
      expect(option.length, 0);

      option.stringValue = "CoAP.NET";
      expect(option.stringValue, "CoAP.NET");
    });

    test('Set int value', () {
      final CoapOption option = CoapOption.create(optionTypeReserved);

      option.intValue = 0;
      expect(option.valueBytes[0], 0);

      option.intValue = 11;
      expect(option.valueBytes[0], 11);

      option.intValue = 255;
      expect(option.valueBytes[0], 255);

      option.intValue = 256;
      expect(option.valueBytes[0], 0);
      expect(option.valueBytes[1], 1);

      option.intValue = 18273;
      expect(option.valueBytes[0], 97);
      expect(option.valueBytes[1], 71);

      option.intValue = 1 << 16;
      expect(option.valueBytes[0], 0);
      expect(option.valueBytes[1], 0);
      expect(option.valueBytes[2], 1);

      option.intValue = 23984773;
      expect(option.valueBytes[0], 133);
      expect(option.valueBytes[1], 250);
      expect(option.valueBytes[2], 109);
      expect(option.valueBytes[3], 1);

      option.intValue = 0xFFFFFFFF;
      expect(option.valueBytes[0], 0xFF);
      expect(option.valueBytes[1], 0xFF);
      expect(option.valueBytes[2], 0xFF);
      expect(option.valueBytes[3], 0xFF);
    });

    test('Set long value', () {
      final CoapOption option = CoapOption.create(optionTypeReserved);

      option.longValue = 0;
      expect(option.valueBytes[0], 0);

      option.longValue = 11;
      expect(option.valueBytes[0], 11);

      option.longValue = 255;
      expect(option.valueBytes[0], 255);

      option.longValue = 256;
      expect(option.valueBytes[0], 0);
      expect(option.valueBytes[1], 1);

      option.longValue = 18273;
      expect(option.valueBytes[0], 97);
      expect(option.valueBytes[1], 71);

      option.longValue = 1 << 16;
      expect(option.valueBytes[0], 0);
      expect(option.valueBytes[1], 0);
      expect(option.valueBytes[2], 1);

      option.longValue = 23984773;
      expect(option.valueBytes[0], 133);
      expect(option.valueBytes[1], 250);
      expect(option.valueBytes[2], 109);
      expect(option.valueBytes[3], 1);

      option.longValue = 0xFFFFFFFF;
      expect(option.valueBytes[0], 0xFF);
      expect(option.valueBytes[1], 0xFF);
      expect(option.valueBytes[2], 0xFF);
      expect(option.valueBytes[3], 0xFF);

      option.longValue = 0x9823749837239845;
      expect(option.valueBytes.toList(), [69, 152, 35, 55, 152, 116, 35, 152]);

      option.longValue = 0xFFFFFFFFFFFFFFFF;
      expect(option.valueBytes[0], 0xFF);
      expect(option.valueBytes[1], 0xFF);
      expect(option.valueBytes[2], 0xFF);
      expect(option.valueBytes[3], 0xFF);
      expect(option.valueBytes[4], 0xFF);
      expect(option.valueBytes[5], 0xFF);
      expect(option.valueBytes[6], 0xFF);
      expect(option.valueBytes[7], 0xFF);
    });

    test('Split', () {
      final List<CoapOption> opts =
      CoapOption.split(optionTypeUriPath, "hello/from/me", "/");
      expect(opts.length, 3);
      expect(opts[0].stringValue, "hello");
      expect(opts[0].type, optionTypeUriPath);
      expect(opts[1].stringValue, "from");
      expect(opts[2].stringValue, "me");

      final List<CoapOption> opts1 =
      CoapOption.split(optionTypeUriPath, "///hello/from/me/again", "/");
      expect(opts1.length, 4);
      expect(opts1[0].stringValue, "hello");
      expect(opts1[0].type, optionTypeUriPath);
      expect(opts1[1].stringValue, "from");
      expect(opts1[2].stringValue, "me");
      expect(opts1[3].stringValue, "again");
    });

    test('Join', () {
      final CoapOption opt1 = CoapOption.createString(
          optionTypeUriPath, "Hello");
      final CoapOption opt2 = CoapOption.createString(
          optionTypeUriPath, "from");
      final CoapOption opt3 = CoapOption.createString(optionTypeUriPath, "me");
      final String str = CoapOption.join([opt1, opt2, opt3], "/");
      expect(str, "Hello/from/me");
    });

    test('Critical', () {
      expect(CoapOption.isCritical(optionTypeUriPath), true);
      expect(CoapOption.isCritical(optionTypeReserved1), false);
    });

    test('Elective', () {
      expect(CoapOption.isElective(optionTypeReserved1), true);
      expect(CoapOption.isElective(optionTypeUriPath), false);
    });

    test('Unsafe', () {
      expect(CoapOption.isUnsafe(optionTypeUriHost), true);
      expect(CoapOption.isUnsafe(optionTypeIfMatch), false);
    });

    test('Safe', () {
      expect(CoapOption.isSafe(optionTypeUriHost), false);
      expect(CoapOption.isSafe(optionTypeIfMatch), true);
    });
  });

  group('Block Option', () {
    test('Get value', () {
      /// Helper function that creates a BlockOption with the specified parameters
      /// and serializes them to a byte array.
      typed.Uint8Buffer toBytes(int szx, bool m, int num) {
        final CoapBlockOption opt =
        new CoapBlockOption.fromParts(optionTypeBlock1, num, szx, m);
        return opt.valueBytes;
      }

      // Original test assumes network byte ordering is needed, hence the reverse
      expect(toBytes(0, false, 0), [0x0]);
      expect(toBytes(0, false, 1), [0x10]);
      expect(toBytes(0, false, 15), [0xf0]);
      expect(toBytes(0, false, 16), [0x01, 0x00].reversed);
      expect(toBytes(0, false, 79), [0x04, 0xf0].reversed);
      expect(toBytes(0, false, 113), [0x07, 0x10].reversed);
      expect(toBytes(0, false, 26387), [0x06, 0x71, 0x30].reversed);
      expect(toBytes(0, false, 1048575), [0xff, 0xff, 0xf0].reversed);
      expect(toBytes(7, false, 1048575), [0xff, 0xff, 0xf7].reversed);
      expect(toBytes(7, true, 1048575), [0xff, 0xff, 0xff].reversed);
    });

    test('Combined', () {
      /// Converts a BlockOption with the specified parameters to a byte array and
      /// back and checks that the result is the same as the original.
      void testCombined(int szx, bool m, int num) {
        final CoapBlockOption block =
        new CoapBlockOption.fromParts(optionTypeBlock1, num, szx, m);
        final CoapBlockOption copy = new CoapBlockOption(optionTypeBlock1);
        copy.valueBytes = block.valueBytes;
        expect(block.szx, copy.szx);
        expect(block.m, copy.m);
        expect(block.num, copy.num);
      }

      testCombined(0, false, 0);
      testCombined(0, false, 1);
      testCombined(0, false, 15);
      testCombined(0, false, 16);
      testCombined(0, false, 79);
      testCombined(0, false, 113);
      testCombined(0, false, 26387);
      testCombined(0, false, 1048575);
      testCombined(7, false, 1048575);
      testCombined(7, true, 1048575);
    });
  });

  group('Media types', () {
    test('Properties', () {
      final int type = CoapMediaType.applicationJson;
      expect(CoapMediaType.name(type), "application/json");
      expect(CoapMediaType.fileExtension(type), "json");
      expect(CoapMediaType.isPrintable(type), true);
      expect(CoapMediaType.isImage(type), false);

      final int unknownType = 200;
      expect(CoapMediaType.name(unknownType), "unknown/200");
      expect(CoapMediaType.fileExtension(unknownType), "unknown/200");
      expect(CoapMediaType.isPrintable(unknownType), false);
      expect(CoapMediaType.isImage(unknownType), false);
    });

    test('Negotiation Content', () {
      final int defaultContentType = 10;
      final List<int> supported = [11, 5];
      List<CoapOption> accepted = new List<CoapOption>();
      final CoapOption opt1 = CoapOption.createVal(optionTypeMaxAge, 10);
      final CoapOption opt2 = CoapOption.createVal(optionTypeContentFormat, 5);
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
      int res = CoapMediaType.parse(null);
      expect(res, CoapMediaType.undefined);

      res = CoapMediaType.parse("application/xml");
      expect(res, CoapMediaType.applicationXml);
    });

    test('Parse wild card', () {
      List<int> res = CoapMediaType.parseWildcard(null);
      expect(res, isNull);

      res = CoapMediaType.parseWildcard("xml*");
      expect(res, [
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
      final CoapConfig conf = new CoapConfig("test/config_all.yaml");
      expect(conf.version, "RFC7252");
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
      //TODO expect(conf.deduplicator,"");
      expect(conf.logTarget, "console");
      expect(conf.logFile, "coap_test.log");
      expect(conf.logError, false);
      expect(conf.logInfo, true);
      expect(conf.logWarn, true);
      expect(conf.logDebug, true);
    });

    test('Default', () {
      final CoapConfig conf = new CoapConfig("test/config_default.yaml");
      expect(conf.version, "RFC7252");
      expect(conf.defaultPort, 5683);
      expect(conf.defaultSecurePort, 5684);
      expect(conf.httpPort, 8080);
      expect(conf.ackTimeout, 2000);
      expect(conf.ackRandomFactor, 1.5);
      expect(conf.ackTimeoutScale, 2.0);
      expect(conf.maxRetransmit, 4);
      expect(conf.maxMessageSize, 1024);
      expect(conf.defaultBlockSize, 512);
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
      //TODO expect(conf.deduplicator,"");
      expect(conf.logTarget, "none");
      expect(conf.logFile, "coaplog.txt");
      expect(conf.logError, true);
      expect(conf.logInfo, false);
      expect(conf.logWarn, false);
      expect(conf.logDebug, false);
    });

    test('Instance', () {
      final CoapConfig conf = new CoapConfig("test/config_default.yaml");
      expect(conf == CoapConfig.inst, isTrue);
    });
  });

  group('Logging', () {
    test('Null', () {
      final CoapLogManager logmanager = new CoapLogManager('none');
      final CoapILogger logger = logmanager.logger;
      expect(logger.isDebugEnabled(), isFalse);
      expect(logger.isErrorEnabled(), isFalse);
      expect(logger.isInfoEnabled(), isFalse);
      expect(logger.isWarnEnabled(), isFalse);
      logger.warn("Warning message");
      logger.info("Information message");
      logger.error("Error message");
      logger.debug("Debug message");
    });

    test('Console', () {
      final CoapConfig conf = new CoapConfig("test/config_logging.yaml");
      expect(conf.logTarget, "console");
      final CoapLogManager logmanager = new CoapLogManager('console');
      final CoapILogger logger = logmanager.logger;
      // Add a string appender to test correct log strings
      LoggerFactory.config["ConsoleLogger"].appenders.add(new StringAppender());
      final StringAppender appender =
          LoggerFactory.config["ConsoleLogger"].appenders.last;
      expect(logger.isDebugEnabled(), isTrue);
      expect(logger.isErrorEnabled(), isTrue);
      expect(logger.isInfoEnabled(), isTrue);
      expect(logger.isWarnEnabled(), isTrue);
      logger.warn("Warning message");
      expect(appender.content.contains("WARN ConsoleLogger: Warning message"),
          isTrue);
      appender.clear();
      logger.info("Information message");
      expect(
          appender.content.contains("INFO ConsoleLogger: Information message"),
          isTrue);
      appender.clear();
      logger.error("Error message");
      expect(appender.content.contains("ERROR ConsoleLogger: Error message"),
          isTrue);
      appender.clear();
      logger.debug("Debug message");
      expect(appender.content.contains("DEBUG ConsoleLogger: Debug message"),
          isTrue);
      appender.clear();
    });

    test('File', () {
      final CoapConfig conf = new CoapConfig("test/config_logging.yaml");
      final CoapLogManager logmanager = new CoapLogManager('file');
      final logFile = new File(conf.logFile);
      if (logFile.existsSync()) {
        logFile.deleteSync();
      }
      final CoapILogger logger = logmanager.logger;
      expect(logger.isDebugEnabled(), isTrue);
      expect(logger.isErrorEnabled(), isTrue);
      expect(logger.isInfoEnabled(), isTrue);
      expect(logger.isWarnEnabled(), isTrue);
      logger.warn("Warning message");
      sleep(const Duration(seconds: 1));
      logger.info("Information message");
      sleep(const Duration(seconds: 1));
      logger.error("Error message");
      sleep(const Duration(seconds: 1));
      logger.debug("Debug message");
      expect(logFile.lengthSync() > 0, isTrue);
    });
  });
}
