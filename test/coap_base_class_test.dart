/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/04/2017
 * Copyright :  S.Hamblett
 */
import 'package:coap/coap.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'dart:convert';
import 'dart:math';

void main() {
  group("Options", () {
    final Utf8Encoder encoder = new Utf8Encoder();

    test('Raw', () {
      final typed.Uint8Buffer raw = new typed.Uint8Buffer(3);
      raw.addAll(encoder.convert("raw"));
      final Option opt = Option.createRaw(optionTypeContentType, raw);
      expect(opt.valueBytes, raw);
      expect(opt.type, optionTypeContentType);
    });

    test('IntValue', () {
      final int oneByteValue = 255;
      final int twoByteValue = oneByteValue + 1;
      final Option opt1 = Option.createVal(optionTypeContentType, oneByteValue);
      final Option opt2 = Option.createVal(optionTypeContentType, twoByteValue);
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
      final Option opt1 =
      Option.createLongVal(optionTypeContentType, fourByteValue);
      final Option opt2 =
      Option.createLongVal(optionTypeContentType, fiveByteValue);
      expect(opt1.length, 4);
      expect(opt2.length, 5);
      expect(opt1.longValue, fourByteValue);
      expect(opt2.longValue, fiveByteValue);
      expect(opt1.type, optionTypeContentType);
      expect(opt2.type, optionTypeContentType);
    });

    test('String', () {
      final String s = "hello world";
      final Option opt = Option.createString(optionTypeContentType, s);
      expect(opt.length, 11);
      expect(s, opt.stringValue);
      expect(opt.type, optionTypeContentType);
    });

    test('Name', () {
      final Option opt = Option.create(optionTypeUriQuery);
      expect(opt.name, "Uri-Query");
    });

    test('Value', () {
      final Option opt = Option.createVal(optionTypeMaxAge, 10);
      expect(opt.value, 10);
      final Option opt1 = Option.createString(optionTypeUriQuery, "Hello");
      expect(opt1.value, "Hello");
      final Option opt2 = Option.create(optionTypeReserved);
      expect(opt2.value, isNull);
      final Option opt3 = Option.create(1000);
      expect(opt3.value, isNull);
    });

    test('Is default', () {
      final Option opt =
      Option.createVal(optionTypeMaxAge, CoapConstants.defaultMaxAge);
      expect(opt.isDefault(), isTrue);
      final Option opt1 = Option.create(optionTypeToken);
      expect(opt1.isDefault(), isTrue);
      final Option opt2 = Option.create(optionTypeReserved);
      expect(opt2.isDefault(), isFalse);
    });

    test('To string', () {
      final Option opt =
      Option.createVal(optionTypeMaxAge, CoapConstants.defaultMaxAge);
      expect(opt.toString(), "Max-Age: 60");
    });

    test('Option format', () {
      expect(Option.getFormatByType(optionTypeMaxAge), optionFormat.integer);
      expect(Option.getFormatByType(optionTypeUriHost), optionFormat.string);
      expect(Option.getFormatByType(optionTypeETag), optionFormat.opaque);
      expect(Option.getFormatByType(1000), optionFormat.unknown);
    });

    test('Hash code', () {
      final Option opt = Option.createVal(optionTypeMaxAge, 10);
      expect(opt.hashCode, 45);
    });

    test('Equality', () {
      final int oneByteValue = 255;
      final int twoByteValue = 256;

      final Option opt1 = Option.createVal(optionTypeContentType, oneByteValue);
      final Option opt2 = Option.createVal(optionTypeContentType, twoByteValue);
      final Option opt22 =
      Option.createVal(optionTypeContentType, twoByteValue);

      expect(opt1 == opt2, isFalse);
      expect(opt2 == opt22, isTrue);
      expect(opt1 == null, isFalse);
    });

    test('Empty token', () {
      final Option opt1 = Option.create(optionTypeToken);
      final Option opt2 = Option.create(optionTypeToken);
      final Option opt22 = Option.createString(optionTypeToken, "full");

      expect(opt1 == opt2, isTrue);
      expect(opt2 == opt22, isFalse);
      expect(opt1.length, 0);
    });

    test('1 Byte token', () {
      final Option opt1 = Option.createVal(optionTypeToken, 0xCD);
      final Option opt2 = Option.createVal(optionTypeToken, 0xCD);
      final Option opt22 = Option.createVal(optionTypeToken, 0xCE);

      expect(opt1 == opt2, isTrue);
      expect(opt2 == opt22, isFalse);
      expect(opt1.length, 1);
    });

    test('2 Byte token', () {
      final Option opt1 = Option.createVal(optionTypeToken, 0xABCD);
      final Option opt2 = Option.createVal(optionTypeToken, 0xABCD);
      final Option opt22 = Option.createVal(optionTypeToken, 0xABCE);

      expect(opt1 == opt2, isTrue);
      expect(opt2 == opt22, isFalse);
      expect(opt1.length, 2);
    });

    test('4 Byte token', () {
      final Option opt1 = Option.createVal(optionTypeToken, 0x1234ABCD);
      final Option opt2 = Option.createVal(optionTypeToken, 0x1234ABCD);
      final Option opt22 = Option.createVal(optionTypeToken, 0x1234ABCE);

      expect(opt1 == opt2, isTrue);
      expect(opt2 == opt22, isFalse);
      expect(opt1.length, 4);
    });

  });

  group('Media types', () {
    test('Properties', () {
      final int type = MediaType.applicationJson;
      expect(MediaType.name(type), "application/json");
      expect(MediaType.fileExtension(type), "json");
      expect(MediaType.isPrintable(type), true);
      expect(MediaType.isImage(type), false);

      final int unknownType = 200;
      expect(MediaType.name(unknownType), "unknown/200");
      expect(MediaType.fileExtension(unknownType), "unknown/200");
      expect(MediaType.isPrintable(unknownType), false);
      expect(MediaType.isImage(unknownType), false);
    });

//    test('Negotiation Content', () {
//      final int defaultContentType = 10;
//      final List<int> accepted = null;
//      final List<Option> supported = new List<Option>();
//      expect(
//          MediaType.negotiationContent(defaultContentType, accepted, supported),
//          defaultContentType);
//    });
  });
}
