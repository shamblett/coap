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
      expect(opt1.length(), 1);
      expect(opt2.length(), 2);
      expect(opt1.intValue, oneByteValue);
      expect(opt2.intValue, twoByteValue);
      expect(opt1.type, optionTypeContentType);
      expect(opt2.type, optionTypeContentType);
    });

    test('LongValue', () {
      final int fourByteValue = pow(2, 32) - 1;
      final int fiveByteValue = fourByteValue + 1;
      final Option opt1 = Option.createLongVal(
          optionTypeContentType, fourByteValue);
      final Option opt2 = Option.createLongVal(
          optionTypeContentType, fiveByteValue);
      expect(opt1.length(), 4);
      expect(opt2.length(), 5);
      expect(opt1.longValue, fourByteValue);
      expect(opt2.longValue, fiveByteValue);
      expect(opt1.type, optionTypeContentType);
      expect(opt2.type, optionTypeContentType);
    });

    test('String', () {
      final String s = "hello world";
      final Option opt = Option.createString(optionTypeContentType, s);
      expect(opt.length(), 11);
      expect(s, opt.stringValue);
      expect(opt.type, optionTypeContentType);
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
