/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 09/05/2018
 * Copyright :  S.Hamblett
 */
import 'dart:convert';
import 'package:coap/coap.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;

void main() {
  group('Options', () {
    const encoder = Utf8Encoder();

    test('Raw', () {
      final raw = typed.Uint8Buffer(3);
      raw.addAll(encoder.convert('raw'));
      final opt = CoapOption.createRaw(optionTypeContentType, raw);
      expect(opt.byteValue, raw);
      expect(opt.type, optionTypeContentType);
    });

    test('IntValue', () {
      const oneByteValue = 255;
      const twoByteValue = oneByteValue + 1;
      final fourByteValue = (1 << 32) - 1;
      final fiveByteValue = fourByteValue + 1;
      final opt1 = CoapOption.createVal(optionTypeContentType, oneByteValue);
      final opt2 = CoapOption.createVal(optionTypeContentType, twoByteValue);
      final opt3 = CoapOption.createVal(optionTypeContentType, fourByteValue);
      final opt4 = CoapOption.createVal(optionTypeContentType, fiveByteValue);
      expect(opt1.length, 1);
      expect(opt2.length, 2);
      expect(opt3.length, 4);
      expect(opt4.length, 8);
      expect(opt1.intValue, oneByteValue);
      expect(opt2.intValue, twoByteValue);
      expect(opt3.intValue, fourByteValue);
      expect(opt4.intValue, fiveByteValue);
      expect(opt1.type, optionTypeContentType);
      expect(opt2.type, optionTypeContentType);
      expect(opt3.type, optionTypeContentType);
      expect(opt4.type, optionTypeContentType);
    });

    test('String', () {
      const s = 'hello world';
      final opt = CoapOption.createString(optionTypeContentType, s);
      expect(opt.length, 11);
      expect(s, opt.stringValue);
      expect(opt.type, optionTypeContentType);
    });

    test('Name', () {
      final opt = CoapOption.create(optionTypeUriQuery);
      expect(opt.name, 'Uri-Query');
    });

    test('Value', () {
      final opt = CoapOption.createVal(optionTypeMaxAge, 10);
      expect(opt.value, 10);
      final opt1 = CoapOption.createUriQuery('Hello');
      expect(opt1.value, 'Hello');
      final opt2 = CoapOption.create(optionTypeReserved);
      expect(opt2.value, isNull);
      final opt3 = CoapOption.create(1000);
      expect(opt3.value, isNull);
    });

    test('Is default', () {
      final opt =
          CoapOption.createVal(optionTypeMaxAge, CoapConstants.defaultMaxAge);
      expect(opt.isDefault(), isTrue);
      final opt2 = CoapOption.create(optionTypeReserved);
      expect(opt2.isDefault(), isFalse);
    });

    test('To string', () {
      final opt =
          CoapOption.createVal(optionTypeMaxAge, CoapConstants.defaultMaxAge);
      expect(opt.toString(), 'Max-Age: 60');
    });

    test('Option format', () {
      expect(
          CoapOption.getFormatByType(optionTypeMaxAge), OptionFormat.integer);
      expect(
          CoapOption.getFormatByType(optionTypeUriHost), OptionFormat.string);
      expect(CoapOption.getFormatByType(optionTypeETag), OptionFormat.opaque);
      expect(CoapOption.getFormatByType(1000), OptionFormat.unknown);
    });

    test('Equality', () {
      const oneByteValue = 255;
      const twoByteValue = 256;

      final opt1 = CoapOption.createVal(optionTypeContentType, oneByteValue);
      final opt2 = CoapOption.createVal(optionTypeContentType, twoByteValue);
      final opt3 = CoapOption.createVal(optionTypeContentType, twoByteValue);

      expect(opt1 == opt2, isFalse);
      expect(opt2 == opt3, isTrue);
    });

    test('Set string value', () {
      final option = CoapOption.create(optionTypeReserved);

      option.stringValue = '';
      expect(option.length, 0);

      option.stringValue = 'CoAP.NET';
      expect(option.stringValue, 'CoAP.NET');
    });

    test('Set int value', () {
      final option = CoapOption.create(optionTypeReserved);

      option.intValue = 0;
      expect(option.byteValue[0], 0);

      option.intValue = 11;
      expect(option.byteValue[0], 11);

      option.intValue = 255;
      expect(option.byteValue[0], 255);

      option.intValue = 256;
      expect(option.byteValue[0], 0);
      expect(option.byteValue[1], 1);

      option.intValue = 18273;
      expect(option.byteValue[0], 97);
      expect(option.byteValue[1], 71);

      option.intValue = 1 << 16;
      expect(option.byteValue[0], 0);
      expect(option.byteValue[1], 0);
      expect(option.byteValue[2], 1);

      option.intValue = 23984773;
      expect(option.byteValue[0], 133);
      expect(option.byteValue[1], 250);
      expect(option.byteValue[2], 109);
      expect(option.byteValue[3], 1);

      option.intValue = 0xFFFFFFFF;
      expect(option.byteValue[0], 0xFF);
      expect(option.byteValue[1], 0xFF);
      expect(option.byteValue[2], 0xFF);
      expect(option.byteValue[3], 0xFF);

      option.intValue = 0x9823749837239845;
      expect(option.byteValue[0], 69);
      expect(option.byteValue[1], 152);
      expect(option.byteValue[2], 35);
      expect(option.byteValue[3], 55);
      expect(option.byteValue[4], 152);
      expect(option.byteValue[5], 116);
      expect(option.byteValue[6], 35);
      expect(option.byteValue[7], 152);

      option.intValue = 0xFFFFFFFFFFFFFFFF;
      expect(option.byteValue[0], 0xFF);
      expect(option.byteValue[1], 0xFF);
      expect(option.byteValue[2], 0xFF);
      expect(option.byteValue[3], 0xFF);
      expect(option.byteValue[4], 0xFF);
      expect(option.byteValue[5], 0xFF);
      expect(option.byteValue[6], 0xFF);
      expect(option.byteValue[7], 0xFF);
    });

    test('Split', () {
      final opts = CoapOption.split(optionTypeUriPath, 'hello/from/me', '/');
      expect(opts.length, 3);
      expect(opts[0].stringValue, 'hello');
      expect(opts[0].type, optionTypeUriPath);
      expect(opts[1].stringValue, 'from');
      expect(opts[2].stringValue, 'me');

      final opts1 =
          CoapOption.split(optionTypeUriPath, '///hello/from/me/again', '/');
      expect(opts1.length, 4);
      expect(opts1[0].stringValue, 'hello');
      expect(opts1[0].type, optionTypeUriPath);
      expect(opts1[1].stringValue, 'from');
      expect(opts1[2].stringValue, 'me');
      expect(opts1[3].stringValue, 'again');
    });

    test('Join', () {
      final opt1 = CoapOption.createString(optionTypeUriPath, 'Hello');
      final opt2 = CoapOption.createString(optionTypeUriPath, 'from');
      final opt3 = CoapOption.createString(optionTypeUriPath, 'me');
      final str = CoapOption.join(<CoapOption>[opt1, opt2, opt3], '/');
      expect(str, 'Hello/from/me');
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
      typed.Uint8Buffer? toBytes(int szx, int num, {required bool m}) {
        final opt = CoapBlockOption.fromParts(optionTypeBlock1, num, szx, m: m);
        return opt.blockValueBytes;
      }

      // Original test assumes network byte ordering is needed, hence the reverse
      expect(toBytes(0, 0, m: false), <int>[0x0]);
      expect(toBytes(0, 1, m: false), <int>[0x10]);
      expect(toBytes(0, 15, m: false), <int>[0xf0]);
      expect(toBytes(0, 16, m: false), <int>[0x01, 0x00].reversed);
      expect(toBytes(0, 79, m: false), <int>[0x04, 0xf0].reversed);
      expect(toBytes(0, 113, m: false), <int>[0x07, 0x10].reversed);
      expect(toBytes(0, 26387, m: false), <int>[0x06, 0x71, 0x30].reversed);
      expect(toBytes(0, 1048575, m: false), <int>[0xff, 0xff, 0xf0].reversed);
      expect(toBytes(7, 1048575, m: false), <int>[0xff, 0xff, 0xf7].reversed);
      expect(toBytes(7, 1048575, m: true), <int>[0xff, 0xff, 0xff].reversed);
    });

    test('Combined', () {
      /// Converts a BlockOption with the specified parameters to a byte array and
      /// back and checks that the result is the same as the original.
      void testCombined(int szx, int num, {required bool m}) {
        final block =
            CoapBlockOption.fromParts(optionTypeBlock1, num, szx, m: m);
        final copy = CoapBlockOption(optionTypeBlock1);
        copy.byteValue = block.byteValue;
        expect(block.szx, copy.szx);
        expect(block.m, copy.m);
        expect(block.num, copy.num);
      }

      testCombined(0, 0, m: false);
      testCombined(0, 1, m: false);
      testCombined(0, 15, m: false);
      testCombined(0, 16, m: false);
      testCombined(0, 79, m: false);
      testCombined(0, 113, m: false);
      testCombined(0, 26387, m: false);
      testCombined(0, 1048575, m: false);
      testCombined(7, 1048575, m: false);
      testCombined(7, 1048575, m: false);
    });
  });
}
