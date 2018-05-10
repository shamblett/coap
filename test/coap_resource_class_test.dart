/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 09/05/2018
 * Copyright :  S.Hamblett
 */
import 'package:coap/coap.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'dart:convert';
import 'dart:math';
import 'dart:io';

void main() {
  group("Endpoint resource", () {
    test('Construction', () {
      CoapRemoteResource res = new CoapRemoteResource("billy");
      expect(res.name, "billy");
      expect(res.hidden, isFalse);
      expect(res.attributes, isNull);
      res = new CoapRemoteResource.hide("fred", true);
      expect(res.name, "fred");
      expect(res.hidden, isTrue);
      expect(res.attributes, isNotNull);
    });

    test('Simple test', () {
      String input = '</sensors/temp>;ct=41;rt=\"TemperatureC\"';
      final CoapRemoteResource root = CoapRemoteResource.newRoot(input);
      final CoapRemoteResource res = root.getResourcePath("/sensors/temp");
      expect(res, isNotNull);
      expect(res.name, "temp");
      expect(res.contentTypeCode, 41);
      expect(res.resourceType, "TemperatureC");
    });
  });
}
