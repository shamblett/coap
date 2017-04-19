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

void main() {
  group("Infrastructure", () {
    final Utf8Encoder encoder = new Utf8Encoder();

    test('Option', () {
      final typed.Uint8Buffer raw = new typed.Uint8Buffer(3);
      raw.addAll(encoder.convert("raw"));
      final Option optRaw = Option.createRaw(optionTypeContentType, raw);
      expect(optRaw.valueBytes, raw);
      expect(optRaw.type, optionTypeContentType);

      final int oneByteValue = 255;
      final int twoByteValue = 256;
      final Option opt1 = Option.createVal(optionTypeContentType, oneByteValue);
      final Option opt2 = Option.createVal(optionTypeContentType, twoByteValue);
      expect(opt1.length, 1);
      expect(opt2.length, 2);
      expect(opt1.intValue, oneByteValue);
      expect(opt2.intValue, twoByteValue);
    });

    test('Media types', () {
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

      final int defaultContentType = 10;
      final List<int> accepted = null;
      final List<Option> supported = new List<Option>();
      expect(
          MediaType.negotiationContent(defaultContentType, accepted, supported),
          defaultContentType);
    });
  });
}
