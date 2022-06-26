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
      final raw = typed.Uint8Buffer(3)..addAll(encoder.convert('raw'));
      final opt = CoapOption.createRaw(OptionType.contentFormat, raw);
      expect(opt.byteValue, raw);
      expect(opt.type, OptionType.contentFormat);
    });

    test('IntValue', () {
      const oneByteValue = 255;
      const twoByteValue = oneByteValue + 1;
      const fourByteValue = (1 << 32) - 1;
      const fiveByteValue = fourByteValue + 1;
      final opt1 = CoapOption.createVal(OptionType.contentFormat, oneByteValue);
      final opt2 = CoapOption.createVal(OptionType.contentFormat, twoByteValue);
      final opt3 =
          CoapOption.createVal(OptionType.contentFormat, fourByteValue);
      final opt4 =
          CoapOption.createVal(OptionType.contentFormat, fiveByteValue);
      expect(opt1.length, 1);
      expect(opt2.length, 2);
      expect(opt3.length, 4);
      expect(opt4.length, 8);
      expect(opt1.intValue, oneByteValue);
      expect(opt2.intValue, twoByteValue);
      expect(opt3.intValue, fourByteValue);
      expect(opt4.intValue, fiveByteValue);
      expect(opt1.type, OptionType.contentFormat);
      expect(opt2.type, OptionType.contentFormat);
      expect(opt3.type, OptionType.contentFormat);
      expect(opt4.type, OptionType.contentFormat);
    });

    test('String', () {
      const s = 'hello world';
      final opt = CoapOption.createString(OptionType.contentFormat, s);
      expect(opt.length, 11);
      expect(s, opt.stringValue);
      expect(opt.type, OptionType.contentFormat);
    });

    test('Name', () {
      final opt = CoapOption.create(OptionType.fromTypeNumber(15));
      expect(opt.name, 'Uri-Query');
    });

    test('Value', () {
      final opt = CoapOption.createVal(OptionType.maxAge, 10);
      expect(opt.value, 10);
      final opt1 = CoapOption.createUriQuery('Hello');
      expect(opt1.value, 'Hello');
    });

    test('Is default', () {
      final opt =
          CoapOption.createVal(OptionType.maxAge, CoapConstants.defaultMaxAge);
      expect(opt.isDefault(), isTrue);
    });

    test('To string', () {
      final opt =
          CoapOption.createVal(OptionType.maxAge, CoapConstants.defaultMaxAge);
      expect(opt.toString(), 'Max-Age: 60');
    });

    test('Option format', () {
      expect(OptionType.maxAge.optionFormat, OptionFormat.integer);
      expect(OptionType.uriHost.optionFormat, OptionFormat.string);
      expect(OptionType.eTag.optionFormat, OptionFormat.opaque);
    });

    test('Equality', () {
      const oneByteValue = 255;
      const twoByteValue = 256;

      final opt1 = CoapOption.createVal(OptionType.contentFormat, oneByteValue);
      final opt2 = CoapOption.createVal(OptionType.contentFormat, twoByteValue);
      final opt3 = CoapOption.createVal(OptionType.contentFormat, twoByteValue);

      expect(opt1 == opt2, isFalse);
      expect(opt2 == opt3, isTrue);
    });

    test('Set string value', () {
      final option = CoapOption.create(OptionType.fromTypeNumber(11))
        ..stringValue = '';
      expect(option.length, 0);

      option.stringValue = 'CoAP.NET';
      expect(option.stringValue, 'CoAP.NET');
    });

    test('Set int value', () {
      final option = CoapOption.create(OptionType.fromTypeNumber(12))
        ..intValue = 0;
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

      // ignore: avoid_js_rounded_ints
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

    test('Join', () {
      final opt1 = CoapOption.createString(OptionType.uriPath, 'Hello');
      final opt2 = CoapOption.createString(OptionType.uriPath, 'from');
      final opt3 = CoapOption.createString(OptionType.uriPath, 'me');
      final str = CoapOption.join(<CoapOption>[opt1, opt2, opt3], '/');
      expect(str, 'Hello/from/me');
    });

    test('Critical', () {
      expect(OptionType.uriPath.isCritical, true);
    });

    test('Elective', () {
      expect(OptionType.uriPath.isElective, false);
    });

    test('Unsafe', () {
      expect(OptionType.uriHost.isUnsafe, true);
      expect(OptionType.ifMatch.isUnsafe, false);
    });

    test('Safe', () {
      expect(OptionType.uriHost.isSafe, false);
      expect(OptionType.ifMatch.isSafe, true);
    });
  });

  group('Block Option', () {
    test('Get value', () {
      /// Helper function that creates a BlockOption with the specified
      /// parameters and serializes them to a byte array.
      typed.Uint8Buffer? toBytes(
        final int szx,
        final int num, {
        required final bool m,
      }) {
        final opt =
            CoapBlockOption.fromParts(OptionType.block1, num, szx, m: m);
        return opt.blockValueBytes;
      }

      // Original test assumes network byte ordering is needed,
      // hence the reverse
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
      /// Converts a BlockOption with the specified parameters to a byte array
      /// and back and checks that the result is the same as the original.
      void testCombined(final int szx, final int num, {required final bool m}) {
        final block =
            CoapBlockOption.fromParts(OptionType.block1, num, szx, m: m);
        final copy = CoapBlockOption(OptionType.block1)
          ..byteValue = block.byteValue;
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
