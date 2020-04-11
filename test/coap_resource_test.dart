/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 09/05/2018
 * Copyright :  S.Hamblett
 */
import 'package:coap/coap.dart';
import 'package:coap/config/coap_config_all.dart';
import 'package:test/test.dart';

void main() {
  final DefaultCoapConfig conf = CoapConfigAll();
  print('Configuration version is ${conf.version}');

  group('Endpoint resource', () {
    test('Construction', () {
      var res = CoapRemoteResource('billy');
      expect(res.name, 'billy');
      expect(res.hidden, isFalse);
      res = CoapRemoteResource.hide('fred', hidden: true);
      expect(res.name, 'fred');
      expect(res.hidden, isTrue);
    });

    test('Simple test - rt first', () {
      const input = '</sensors/temp>;rt="TemperatureC";ct=41';
      final root = CoapRemoteResource.newRoot(input);
      final res = root.getResourcePath('/sensors/temp');
      expect(res, isNotNull);
      expect(res.name, 'temp');
      expect(res.contentTypeCode, 41);
      expect(res.resourceType, 'TemperatureC');
      expect(res.observable, isFalse);
    });
    test('Simple test - ct first', () {
      const input = '</sensors/temp>;ct=42;rt="TemperatureF"';
      final root = CoapRemoteResource.newRoot(input);
      final res = root.getResourcePath('/sensors/temp');
      expect(res, isNotNull);
      expect(res.name, 'temp');
      expect(res.contentTypeCode, 42);
      expect(res.resourceType, 'TemperatureF');
      expect(res.observable, isFalse);
    });
    test('Simple test - boolean value', () {
      const input = '</sensors/temp>;ct=42;rt="TemperatureF";obs';
      final root = CoapRemoteResource.newRoot(input);
      final res = root.getResourcePath('/sensors/temp');
      expect(res, isNotNull);
      expect(res.name, 'temp');
      expect(res.contentTypeCode, 42);
      expect(res.resourceType, 'TemperatureF');
      expect(res.observable, isTrue);
    });
    test('Extended test', () {
      const input = '</my/Päth>;rt="MyName";if="/someRef/path";ct=42;obs;sz=20';
      final root = CoapRemoteResource.newRoot(input);

      final my = CoapRemoteResource('my');
      my.resourceType = 'replacement';
      root.addSubResource(my);

      CoapRemoteResource res = root.getResourcePath('/my/Päth');
      expect(res, isNotNull);
      res = root.getResourcePath('my/Päth');
      expect(res, isNotNull);
      res = root.getResourcePath('my');
      res = res.getResourcePath('Päth');
      expect(res, isNotNull);
      res = res.getResourcePath('/my/Päth');
      expect(res, isNotNull);
      expect(res.name, 'Päth');
      expect(res.path, '/my/Päth');
      expect(res.resourceType, 'MyName');
      expect(res.interfaceDescriptions[0], '/someRef/path');
      expect(res.contentTypeCode, 42);
      expect(res.maximumSizeEstimate, 20);
      expect(res.observable, isTrue);

      res = root.getResourcePath('my');
      expect(res, isNotNull);
      expect(res.resourceTypes.toList()[0], 'replacement');
    });
    test('Conversion test', () {
      const link1 =
          '</myUri/something>;ct=42;if="/someRef/path";obs;rt="MyName";sz=10';
      const link2 = '</myUri>;rt="NonDefault"';
      const link3 = '</a>';
      const format = '$link1,$link2,$link3';
      final res = CoapRemoteResource.newRoot(format);
      final result =
          CoapLinkFormat.serializeOptions(res, null, recursive: true);
      expect(result, '$link3,$link2,$link1');
    });
    test('Concrete test', () {
      const link =
          '</careless>;rt="SepararateResponseTester";title="This resource will ACK anything, but never send a separate response",</feedback>;rt="FeedbackMailSender";title="POST feedback using mail",</helloWorld>;rt="HelloWorldDisplayer";title="GET a friendly greeting!",</image>;ct=21;ct=22;ct=23;ct=24;rt="Image";sz=18029;title="GET an image with different content-types",</large>;rt="block";title="Large resource",</large_update>;rt="block";rt="observe";title="Large resource that can be updated using PUT method",</mirror>;rt="RequestMirroring";title="POST request to receive it back as echo",</obs>;obs;rt="observe";title="Observable resource which changes every 5 seconds",</query>;title="Resource accepting query parameters",</seg1/seg2/seg3>;title="Long path resource",</separate>;title="Resource which cannot be served immediately and which cannot be acknowledged in a piggy-backed way",</storage>;obs;rt="Storage";title="PUT your data here or POST resources!",</test>;title="Default test resource",</timeResource>;rt="CurrentTime";title="GET the current time",</toUpper>;rt="UppercaseConverter";title="POST text here to convert it to uppercase",</weatherResource>;rt="ZurichWeather";title="GET the current weather in zurich"';
      const reco =
          '</careless>;rt="SepararateResponseTester";title="This resource will ACK anything, but never send a separate response",</feedback>;rt="FeedbackMailSender";title="POST feedback using mail",</helloWorld>;rt="HelloWorldDisplayer";title="GET a friendly greeting!",</image>;title="GET an image with different content-types";rt="Image";sz=18029;ct=24;ct=23;ct=22;ct=21,</large>;rt="block";title="Large resource",</large_update>;rt="block";rt="observe";title="Large resource that can be updated using PUT method",</mirror>;rt="RequestMirroring";title="POST request to receive it back as echo",</obs>;obs;rt="observe";title="Observable resource which changes every 5 seconds",</query>;title="Resource accepting query parameters",</seg1/seg2/seg3>;title="Long path resource",</separate>;title="Resource which cannot be served immediately and which cannot be acknowledged in a piggy-backed way",</storage>;obs;rt="Storage";title="PUT your data here or POST resources!",</test>;title="Default test resource",</timeResource>;rt="CurrentTime";title="GET the current time",</toUpper>;rt="UppercaseConverter";title="POST text here to convert it to uppercase",</weatherResource>;rt="ZurichWeather";title="GET the current weather in zurich"';
      final res = CoapRemoteResource.newRoot(link);
      final result =
          CoapLinkFormat.serializeOptions(res, null, recursive: true);
      expect(result, reco);
    });
    test('Match test', () {
      const link1 =
          '</myUri/something>;ct=42;if="/someRef/path\";obs;rt=\"MyName";sz=10';
      const link2 = '</myUri>;ct=50;rt="MyName"';
      const link3 = '</a>;sz=10;rt="MyNope"';
      const format = '$link1,$link2,$link3';
      final res = CoapRemoteResource.newRoot(format);

      final query = <CoapOption>[];
      query.add(CoapOption.createString(optionTypeUriQuery, 'rt=MyName'));

      final queried =
          CoapLinkFormat.serializeOptions(res, query, recursive: true);
      expect(queried, '$link2,$link1');
    });
  });
}
