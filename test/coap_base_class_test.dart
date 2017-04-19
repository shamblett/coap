/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/04/2017
 * Copyright :  S.Hamblett
 */
import 'package:coap/coap.dart';
import 'package:test/test.dart';
//import 'package:typed_data/typed_data.dart' as typed;

void main() {
  group("Options", () {
    test('Option', () {});

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
