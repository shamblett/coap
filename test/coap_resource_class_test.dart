/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 09/05/2018
 * Copyright :  S.Hamblett
 */
import 'package:coap/coap.dart';
import 'package:test/test.dart';

void main() {
  final CoapConfig conf = new CoapConfig("test/config_logging.yaml");

  group("Endpoint resource", () {
    test('Construction', () {
      CoapRemoteResource res = new CoapRemoteResource("billy");
      expect(res.name, "billy");
      expect(res.hidden, isFalse);
      res = new CoapRemoteResource.hide("fred", true);
      expect(res.name, "fred");
      expect(res.hidden, isTrue);
    });

    test('Simple test - rt first', () {
      final String input = '</sensors/temp>;rt="TemperatureC";ct=41';
      final CoapRemoteResource root = CoapRemoteResource.newRoot(input);
      final CoapRemoteResource res = root.getResourcePath("/sensors/temp");
      expect(res, isNotNull);
      expect(res.name, "temp");
      expect(res.contentTypeCode, 41);
      expect(res.resourceType, "TemperatureC");
    });
    test('Simple test - ct first', () {
      final String input = '</sensors/temp>;ct=42;rt="TemperatureF"';
      final CoapRemoteResource root = CoapRemoteResource.newRoot(input);
      final CoapRemoteResource res = root.getResourcePath("/sensors/temp");
      expect(res, isNotNull);
      expect(res.name, "temp");
      expect(res.contentTypeCode, 42);
      expect(res.resourceType, "TemperatureF");
    });
    test('Extended test', () {
      final String input = "</my/Päth>;rt=\"MyName\";if=\"/someRef/path\";ct=42;obs;sz=20";
      final CoapRemoteResource root = CoapRemoteResource.newRoot(input);

      final CoapRemoteResource my = new CoapRemoteResource("my");
      my.resourceType = "replacement";
      root.addSubResource(my);

      CoapRemoteResource res = root.getResourcePath("/my/Päth");
      expect(res, isNotNull);
      res = root.getResourcePath("my/Päth");
      expect(res, isNotNull);
      res = root.getResourcePath("my");
      res = res.getResourcePath("Päth");
      expect(res, isNotNull);
      res = res.getResourcePath("/my/Päth");
      expect(res, isNotNull);
      expect(res.name, "Päth");
      expect(res.path, "/my/Päth");
      expect(res.resourceType, "MyName");
      expect(res.interfaceDescriptions[0], "/someRef/path");
      expect(res.contentTypeCode, 42);
      expect(res.maximumSizeEstimate, 20);
      expect(res.observable, isTrue);

      res = root.getResourcePath("my");
      expect(res, isNotNull);
      expect(res.resourceTypes.toList()[0], "replacement");
    });
    test('Conversion test', () {
      final String link1 = "</myUri/something>;ct=42;if=\"/someRef/path\";obs;rt=\"MyName\";sz=10";
      final String link2 = "</myUri>;rt=\"NonDefault\"";
      final String link3 = "</a>";
      final String format = link1 + "," + link2 + "," + link3;
      final CoapRemoteResource res = CoapRemoteResource.newRoot(format);
      final String result = CoapLinkFormat.serializeOptions(res, null, true);
      expect(result, link3 + "," + link2 + "," + link1);
    });
  });
}
