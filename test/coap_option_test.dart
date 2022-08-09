/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 09/05/2018
 * Copyright :  S.Hamblett
 */
import 'dart:convert';
import 'package:coap/coap.dart';
import 'package:coap/src/option/coap_option_type.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;

void main() {
  group('Options', () {
    const encoder = Utf8Encoder();

    test('Raw', () {
      final raw = typed.Uint8Buffer()..addAll(encoder.convert('raw'));
      final opt = Size2Option.parse(raw);
      expect(opt.byteValue, raw);
      expect(opt.type, OptionType.size2);
    });

    test('IntValue', () {
      const oneByteValue = 255;
      const twoByteValue = oneByteValue + 1;
      const fourByteValue = (1 << 32) - 1;
      const fiveByteValue = fourByteValue + 1;
      final opt1 = Size2Option(oneByteValue);
      final opt2 = Size2Option(twoByteValue);
      final opt3 = Size2Option(fourByteValue);
      expect(
        () => Size2Option(fiveByteValue),
        throwsA(isA<UnknownElectiveOptionException>()),
      );
      expect(opt1.length, 1);
      expect(opt2.length, 2);
      expect(opt3.length, 4);
      expect(opt1.value, oneByteValue);
      expect(opt2.value, twoByteValue);
      expect(opt3.value, fourByteValue);
      expect(opt1.type, OptionType.size2);
      expect(opt2.type, OptionType.size2);
      expect(opt3.type, OptionType.size2);
    });

    test('String', () {
      const s = 'hello world';
      final opt = UriHostOption(s);
      expect(opt.length, 11);
      expect(s, opt.value);
      expect(opt.type, OptionType.uriHost);
    });

    test('Name', () {
      final opt = UriQueryOption.parse(typed.Uint8Buffer());
      expect(opt.name, 'Uri-Query');
    });

    test('Value', () {
      final opt = MaxAgeOption(10);
      expect(opt.value, 10);

      final opt1 = UriQueryOption('Hello');
      expect(opt1.value, 'Hello');
    });

    test('Is default', () {
      final opt = MaxAgeOption(OptionType.maxAge.defaultValue! as int);
      expect(opt.isDefault, isTrue);
    });

    test('To string', () {
      final opt = MaxAgeOption(OptionType.maxAge.defaultValue! as int);
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

      final opt1 = ContentFormatOption(oneByteValue);

      final opt2 = ContentFormatOption(twoByteValue);

      final opt3 = ContentFormatOption(twoByteValue);

      expect(opt1 == opt2, isFalse);
      expect(opt2 == opt3, isTrue);
    });

    test('Join', () {
      final opt1 = UriPathOption('Hello');
      final opt2 = UriPathOption('from');
      final opt3 = UriPathOption('me');
      final str = [opt1, opt2, opt3]
          .map((final option) => option.valueString)
          .join('/');
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
        final opt = Block1Option.fromParts(num, szx, m: m);
        return opt.blockValueBytes;
      }

      // Test assumes network byte ordering is needed
      expect(toBytes(0, 0, m: false), <int>[]);
      expect(toBytes(0, 1, m: false), [0x10]);
      expect(toBytes(0, 15, m: false), [0xf0]);
      expect(
        toBytes(0, 16, m: false),
        [0x01, 0x00].reversed,
      );
      expect(
        toBytes(0, 79, m: false),
        [0x04, 0xf0].reversed,
      );
      expect(
        toBytes(0, 113, m: false),
        [0x07, 0x10].reversed,
      );

      expect(
        () => toBytes(0, 26387, m: false),
        throwsA(isA<UnknownCriticalOptionException>()),
      );
      expect(
        () => toBytes(0, 1048575, m: false),
        throwsA(isA<UnknownCriticalOptionException>()),
      );
    });

    test('Combined', () {
      /// Converts a BlockOption with the specified parameters to a byte array
      /// and back and checks that the result is the same as the original.
      void testCombined(final int szx, final int num, {required final bool m}) {
        final block = Block1Option.fromParts(num, szx, m: m);
        final copy = Block1Option.parse(block.byteValue);
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

      expect(
        () => testCombined(0, 26387, m: false),
        throwsA(isA<UnknownCriticalOptionException>()),
      );
      expect(
        () => testCombined(0, 1048575, m: false),
        throwsA(isA<UnknownCriticalOptionException>()),
      );
    });
  });
}
