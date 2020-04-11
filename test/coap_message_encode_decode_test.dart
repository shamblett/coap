/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/04/2017
 * Copyright :  S.Hamblett
 */
import 'package:coap/coap.dart';
import 'package:coap/config/coap_config_logging.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;

void main() {
  const leq = ListEquality<dynamic>();
  // ignore: unused_local_variable
  final DefaultCoapConfig conf = CoapConfigLogging();
  group('COAP All', () {
    final check = <String, List<List<int>>>{
      'draft-ietf-core-coap-03': <List<int>>[
        <int>[64, 1, 48, 57, 112, 97, 121, 108, 111, 97, 100],
        <int>[
          66,
          1,
          48,
          57,
          26,
          116,
          101,
          120,
          116,
          47,
          112,
          108,
          97,
          105,
          110,
          17,
          30,
          112,
          97,
          121,
          108,
          111,
          97,
          100
        ],
        <int>[
          79,
          1,
          48,
          57,
          17,
          97,
          208,
          224,
          224,
          224,
          224,
          224,
          224,
          224,
          224,
          224,
          224,
          224,
          224,
          253,
          101,
          120,
          116,
          101,
          110,
          100,
          32,
          111,
          112,
          116,
          105,
          111,
          110,
          112,
          97,
          121,
          108,
          111,
          97,
          100
        ]
      ],
      'draft-ietf-core-coap-08': <List<int>>[
        <int>[64, 1, 48, 57, 112, 97, 121, 108, 111, 97, 100],
        <int>[
          66,
          1,
          48,
          57,
          26,
          116,
          101,
          120,
          116,
          47,
          112,
          108,
          97,
          105,
          110,
          17,
          30,
          112,
          97,
          121,
          108,
          111,
          97,
          100
        ],
        <int>[
          79,
          1,
          48,
          57,
          17,
          97,
          208,
          224,
          224,
          224,
          224,
          224,
          224,
          224,
          224,
          224,
          224,
          224,
          224,
          253,
          101,
          120,
          116,
          101,
          110,
          100,
          32,
          111,
          112,
          116,
          105,
          111,
          110,
          112,
          97,
          121,
          108,
          111,
          97,
          100
        ]
      ],
      'draft-ietf-core-coap-12': <List<int>>[
        <int>[64, 1, 48, 57, 112, 97, 121, 108, 111, 97, 100],
        <int>[
          66,
          1,
          48,
          57,
          202,
          116,
          101,
          120,
          116,
          47,
          112,
          108,
          97,
          105,
          110,
          33,
          30,
          112,
          97,
          121,
          108,
          111,
          97,
          100
        ],
        <int>[
          66,
          1,
          48,
          57,
          193,
          97,
          242,
          21,
          29,
          101,
          120,
          116,
          101,
          110,
          100,
          32,
          111,
          112,
          116,
          105,
          111,
          110,
          112,
          97,
          121,
          108,
          111,
          97,
          100
        ],
        <int>[
          85,
          2,
          0,
          7,
          18,
          34,
          239,
          5,
          88,
          12,
          254,
          157,
          5,
          177,
          40,
          65,
          40,
          53,
          11,
          82,
          165,
          77,
          3
        ],
        <int>[
          87,
          69,
          0,
          9,
          70,
          1,
          0,
          0,
          0,
          0,
          1,
          79,
          34,
          47,
          111,
          110,
          101,
          47,
          116,
          119,
          111,
          47,
          116,
          104,
          114,
          101,
          101,
          47,
          102,
          111,
          117,
          114,
          47,
          102,
          105,
          118,
          101,
          47,
          115,
          105,
          120,
          47,
          115,
          101,
          118,
          101,
          110,
          47,
          101,
          105,
          103,
          104,
          116,
          47,
          110,
          105,
          110,
          101,
          47,
          116,
          101,
          110,
          182,
          22,
          255,
          0,
          78,
          100,
          22,
          243,
          8,
          92,
          42,
          65,
          114,
          98,
          105,
          116,
          114,
          97,
          114,
          121,
          49,
          10,
          65,
          114,
          98,
          105,
          116,
          114,
          97,
          114,
          121,
          50,
          10,
          65,
          114,
          98,
          105,
          116,
          114,
          97,
          114,
          121,
          51,
          243,
          17,
          171,
          4,
          159,
          148,
          202,
          113
        ]
      ],
      'draft-ietf-core-coap-13': <List<int>>[
        <int>[64, 1, 48, 57, 255, 112, 97, 121, 108, 111, 97, 100],
        <int>[
          64,
          1,
          48,
          57,
          202,
          116,
          101,
          120,
          116,
          47,
          112,
          108,
          97,
          105,
          110,
          33,
          30,
          255,
          112,
          97,
          121,
          108,
          111,
          97,
          100
        ],
        <int>[
          64,
          1,
          48,
          57,
          193,
          97,
          221,
          172,
          0,
          101,
          120,
          116,
          101,
          110,
          100,
          32,
          111,
          112,
          116,
          105,
          111,
          110,
          255,
          112,
          97,
          121,
          108,
          111,
          97,
          100
        ],
        <int>[
          85,
          2,
          0,
          7,
          11,
          82,
          165,
          77,
          3,
          18,
          34,
          239,
          5,
          88,
          12,
          254,
          157,
          5,
          177,
          40,
          65,
          40
        ],
        <int>[
          86,
          69,
          0,
          9,
          22,
          255,
          0,
          78,
          100,
          22,
          70,
          1,
          0,
          0,
          0,
          0,
          1,
          77,
          36,
          47,
          111,
          110,
          101,
          47,
          116,
          119,
          111,
          47,
          116,
          104,
          114,
          101,
          101,
          47,
          102,
          111,
          117,
          114,
          47,
          102,
          105,
          118,
          101,
          47,
          115,
          105,
          120,
          47,
          115,
          101,
          118,
          101,
          110,
          47,
          101,
          105,
          103,
          104,
          116,
          47,
          110,
          105,
          110,
          101,
          47,
          116,
          101,
          110,
          234,
          73,
          240,
          65,
          114,
          98,
          105,
          116,
          114,
          97,
          114,
          121,
          49,
          10,
          65,
          114,
          98,
          105,
          116,
          114,
          97,
          114,
          121,
          50,
          10,
          65,
          114,
          98,
          105,
          116,
          114,
          97,
          114,
          121,
          51,
          228,
          148,
          91,
          159,
          148,
          202,
          113
        ]
      ],
      'draft-ietf-core-coap-18': <List<int>>[
        <int>[64, 1, 48, 57, 255, 112, 97, 121, 108, 111, 97, 100],
        <int>[
          64,
          1,
          48,
          57,
          202,
          116,
          101,
          120,
          116,
          47,
          112,
          108,
          97,
          105,
          110,
          33,
          30,
          255,
          112,
          97,
          121,
          108,
          111,
          97,
          100
        ],
        <int>[
          64,
          1,
          48,
          57,
          193,
          97,
          221,
          172,
          0,
          101,
          120,
          116,
          101,
          110,
          100,
          32,
          111,
          112,
          116,
          105,
          111,
          110,
          255,
          112,
          97,
          121,
          108,
          111,
          97,
          100
        ],
        <int>[
          85,
          2,
          0,
          7,
          11,
          82,
          165,
          77,
          3,
          18,
          34,
          239,
          5,
          88,
          12,
          254,
          157,
          5,
          177,
          40,
          81,
          40
        ],
        <int>[
          86,
          69,
          0,
          9,
          22,
          255,
          0,
          78,
          100,
          22,
          70,
          1,
          0,
          0,
          0,
          0,
          1,
          77,
          36,
          47,
          111,
          110,
          101,
          47,
          116,
          119,
          111,
          47,
          116,
          104,
          114,
          101,
          101,
          47,
          102,
          111,
          117,
          114,
          47,
          102,
          105,
          118,
          101,
          47,
          115,
          105,
          120,
          47,
          115,
          101,
          118,
          101,
          110,
          47,
          101,
          105,
          103,
          104,
          116,
          47,
          110,
          105,
          110,
          101,
          47,
          116,
          101,
          110,
          234,
          73,
          240,
          65,
          114,
          98,
          105,
          116,
          114,
          97,
          114,
          121,
          49,
          10,
          65,
          114,
          98,
          105,
          116,
          114,
          97,
          114,
          121,
          50,
          10,
          65,
          114,
          98,
          105,
          116,
          114,
          97,
          114,
          121,
          51,
          228,
          148,
          91,
          159,
          148,
          202,
          113
        ]
      ]
    };

    /// Helper functions
    void printData(String name, List<int> data, int testNo) {
      print('Draft name is - $name');
      print('Test number is $testNo');
      print('Data is - $data');
      print('Chk  is - ${check[name][testNo]}');
    }

    void checkData(String name, typed.Uint8Buffer data, int testNo) {
      printData(name, data.toList(), testNo);
      expect(data.toList().length, check[name][testNo].length);
      expect(leq.equals(data.toList(), check[name][testNo]), isTrue);
    }

    void testMessage(CoapISpec spec, int testNo) {
      final CoapMessage msg =
          CoapRequest.isConfirmable(CoapCode.methodGET, confirmable: true);

      msg.id = 12345;
      msg.payload = typed.Uint8Buffer()..addAll('payload'.codeUnits);
      final data = spec.encode(msg);
      checkData(spec.name, data, testNo);
      final convMsg = spec.decode(data);
      expect(msg.code, convMsg.code);
      expect(msg.type, convMsg.type);
      expect(msg.id, convMsg.id);
      expect(msg.getAllOptions().length, convMsg.getAllOptions().length);
      expect(
          leq.equals(msg.payload.toList(), convMsg.payload.toList()), isTrue);
      expect(msg.payloadString, convMsg.payloadString);
    }

    void testMessageWithOptions(CoapISpec spec, int testNo) {
      final CoapMessage msg =
          CoapRequest.isConfirmable(CoapCode.methodGET, confirmable: true);

      msg.id = 12345;
      msg.payload = typed.Uint8Buffer()..addAll('payload'.codeUnits);
      msg.addOption(
          CoapOption.createString(optionTypeContentType, 'text/plain'));
      msg.addOption(CoapOption.createVal(optionTypeMaxAge, 30));
      expect(
          msg.getFirstOption(optionTypeContentType).stringValue, 'text/plain');
      expect(msg.getFirstOption(optionTypeMaxAge).value, 30);
      final data = spec.encode(msg);
      checkData(spec.name, data, testNo);
      final convMsg = spec.decode(data);

      expect(msg.code, convMsg.code);
      expect(msg.type, convMsg.type);
      expect(msg.id, convMsg.id);
      expect(msg.getAllOptions().length, convMsg.getAllOptions().length);
      expect(
          leq.equals(
              msg.getAllOptions().toList(), convMsg.getAllOptions().toList()),
          isTrue);
      expect(convMsg.getFirstOption(optionTypeContentType).stringValue,
          'text/plain');
      expect(convMsg.getFirstOption(optionTypeMaxAge).value, 30);
      expect(
          leq.equals(msg.payload.toList(), convMsg.payload.toList()), isTrue);
    }

    void testMessageWithExtendedOption(CoapISpec spec, int testNo) {
      final CoapMessage msg =
          CoapRequest.isConfirmable(CoapCode.methodGET, confirmable: true);

      msg.id = 12345;
      msg.addOption(CoapOption.createString(12, 'a'));
      msg.addOption(CoapOption.createString(197, 'extend option'));
      expect(msg.getFirstOption(12).stringValue, 'a');
      expect(msg.getFirstOption(197).stringValue, 'extend option');
      msg.payload = typed.Uint8Buffer()..addAll('payload'.codeUnits);

      final data = spec.encode(msg);
      checkData(spec.name, data, testNo);
      final convMsg = spec.decode(data);

      expect(msg.code, convMsg.code);
      expect(msg.type, convMsg.type);
      expect(msg.id, convMsg.id);
      expect(msg.getAllOptions().length, convMsg.getAllOptions().length);
      expect(
          leq.equals(
              msg.getAllOptions().toList(), convMsg.getAllOptions().toList()),
          isTrue);
      expect(convMsg.getFirstOption(12).stringValue, 'a');
      expect(
          leq.equals(msg.payload.toList(), convMsg.payload.toList()), isTrue);

      final extendOpt = convMsg.getFirstOption(197);
      expect(extendOpt, isNotNull);
      expect(extendOpt.stringValue, 'extend option');
    }

    void testRequestParsing(CoapISpec spec, int testNo) {
      final request =
          CoapRequest.isConfirmable(CoapCode.methodPOST, confirmable: false);
      request.id = 7;
      request.token = typed.Uint8Buffer()..addAll(<int>[11, 82, 165, 77, 3]);
      request
          .addIfMatchOpaque(typed.Uint8Buffer()..addAll(<int>[34, 239]))
          .addIfMatchOpaque(
              typed.Uint8Buffer()..addAll(<int>[88, 12, 254, 157, 5]));
      request.contentType = 40;
      request.accept = 40;

      final bytes = spec.encode(request);
      checkData(spec.name, bytes, testNo);
      final decoder = spec.newMessageDecoder(bytes);
      expect(decoder.isRequest, isTrue);

      final result = decoder.decodeRequest();
      expect(request.id, result.id);
      expect(leq.equals(request.token.toList(), result.token.toList()), isTrue);
      expect(
          leq.equals(request.getAllOptions().toList(),
              result.getAllOptions().toList()),
          isTrue);
    }

    void testResponseParsing(CoapISpec spec, int testNo) {
      final response = CoapResponse(CoapCode.content);
      response.type = CoapMessageType.non;
      response.id = 9;
      response.token = typed.Uint8Buffer()
        ..addAll(<int>[22, 255, 0, 78, 100, 22]);
      response.addETagOpaque(
          typed.Uint8Buffer()..addAll(<int>[1, 0, 0, 0, 0, 1]))
        ..addLocationPath('/one/two/three/four/five/six/seven/eight/nine/ten')
        ..addOption(CoapOption.createVal(
            57453, 0x71ca949f)) // C# 'Arbitrary'.hashCode()
        ..addOption(CoapOption.createString(19205, 'Arbitrary1'))
        ..addOption(CoapOption.createString(19205, 'Arbitrary2'))
        ..addOption(CoapOption.createString(19205, 'Arbitrary3'));

      final bytes = spec.encode(response);
      checkData(spec.name, bytes, testNo);

      final decoder = spec.newMessageDecoder(bytes);
      expect(decoder.isResponse, isTrue);

      final result = decoder.decodeResponse();
      expect(response.id, result.id);
      expect(
          leq.equals(response.token.toList(), result.token.toList()), isTrue);
      expect(
          leq.equals(response.getOptions(57453).toList(),
              result.getOptions(57453).toList()),
          isTrue);
      expect(
          leq.equals(response.getOptions(19205).toList(),
              result.getOptions(19205).toList()),
          isTrue);
      expect(
          response.etags.toList().toString(), result.etags.toList().toString());
      expect(
          leq.equals(
              response.locationPaths.toList(), result.locationPaths.toList()),
          isTrue);
    }

    test('TestDraft03', () {
      testMessage(CoapDraft03(), 0);
      testMessageWithOptions(CoapDraft03(), 1);
      testMessageWithExtendedOption(CoapDraft03(), 2);
    });
    test('TestDraft08', () {
      testMessage(CoapDraft08(), 0);
      testMessageWithOptions(CoapDraft08(), 1);
      testMessageWithExtendedOption(CoapDraft08(), 2);
    });
    test('TestDraft12', () {
      testMessage(CoapDraft12(), 0);
      testMessageWithOptions(CoapDraft12(), 1);
      testMessageWithExtendedOption(CoapDraft12(), 2);
      testRequestParsing(CoapDraft12(), 3);
      testResponseParsing(CoapDraft12(), 4);
    });
    test('TestDraft13', () {
      testMessage(CoapDraft13(), 0);
      testMessageWithOptions(CoapDraft13(), 1);
      testMessageWithExtendedOption(CoapDraft13(), 2);
      testRequestParsing(CoapDraft13(), 3);
      testResponseParsing(CoapDraft13(), 4);
    });
    test('TestDraft18', () {
      testMessage(CoapDraft18(), 0);
      testMessageWithOptions(CoapDraft18(), 1);
      testMessageWithExtendedOption(CoapDraft18(), 2);
      testRequestParsing(CoapDraft18(), 3);
      testResponseParsing(CoapDraft18(), 4);
    });
  });
}
