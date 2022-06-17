// ignore_for_file: avoid_print

/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/04/2017
 * Copyright :  S.Hamblett
 */
import 'package:coap/coap.dart';
import 'package:coap/src/coap_message.dart';
import 'package:coap/src/coap_response.dart';
import 'package:coap/src/specification/coap_ispec.dart';
import 'package:coap/src/specification/rfcs/coap_rfc7252.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;

void main() {
  const leq = ListEquality<dynamic>();
  // ignore: unused_local_variable
  final DefaultCoapConfig conf = CoapConfigDefault();
  group('COAP All', () {
    final check = <String, List<List<int>>>{
      'RFC 7252': <List<int>>[
        <int>[64, 1, 48, 57, 255, 112, 97, 121, 108, 111, 97, 100],
        <int>[
          64,
          1,
          48,
          57,
          193,
          0,
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
          0,
          255,
          112,
          97,
          121,
          108,
          111,
          97,
          100,
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
        ]
      ]
    };

    /// Helper functions
    void printData(final String name, final List<int> data, final int testNo) {
      print('Specification name is - $name');
      print('Test number is $testNo');
      print('Data is - $data');
      print('Chk  is - ${check[name]![testNo]}');
    }

    void checkData(
      final String name,
      final typed.Uint8Buffer data,
      final int testNo,
    ) {
      printData(name, data.toList(), testNo);
      expect(data.toList().length, check[name]![testNo].length);
      expect(leq.equals(data.toList(), check[name]![testNo]), isTrue);
    }

    void testMessage(final CoapISpec spec, final int testNo) {
      final CoapMessage msg = CoapRequest(CoapCode.methodGET)
        ..id = 12345
        ..payload = (typed.Uint8Buffer()..addAll('payload'.codeUnits));
      final data = spec.encode(msg)!;
      checkData(spec.name, data, testNo);
      final convMsg = spec.decode(data)!;
      expect(msg.code, convMsg.code);
      expect(msg.type, convMsg.type);
      expect(msg.id, convMsg.id);
      expect(msg.getAllOptions().length, convMsg.getAllOptions().length);
      expect(
        leq.equals(msg.payload!.toList(), convMsg.payload!.toList()),
        isTrue,
      );
      expect(msg.payloadString, convMsg.payloadString);
    }

    void testMessageWithOptions(final CoapISpec spec, final int testNo) {
      final CoapMessage msg = CoapRequest(CoapCode.methodGET)
        ..id = 12345
        ..payload = (typed.Uint8Buffer()..addAll('payload'.codeUnits))
        ..addOption(
          CoapOption.createVal(
            OptionType.contentFormat,
            CoapMediaType.textPlain,
          ),
        )
        ..addOption(CoapOption.createVal(OptionType.maxAge, 30));
      expect(msg.getFirstOption(OptionType.contentFormat)!.intValue, 0);
      expect(msg.getFirstOption(OptionType.maxAge)!.value, 30);
      final data = spec.encode(msg)!;
      checkData(spec.name, data, testNo);
      final convMsg = spec.decode(data)!;

      expect(msg.code, convMsg.code);
      expect(msg.type, convMsg.type);
      expect(msg.id, convMsg.id);
      expect(msg.getAllOptions().length, convMsg.getAllOptions().length);
      expect(
        leq.equals(
          msg.getAllOptions().toList(),
          convMsg.getAllOptions().toList(),
        ),
        isTrue,
      );
      expect(
        convMsg.getFirstOption(OptionType.contentFormat)!.intValue,
        CoapMediaType.textPlain,
      );
      expect(convMsg.getFirstOption(OptionType.maxAge)!.value, 30);
      expect(
        leq.equals(msg.payload!.toList(), convMsg.payload!.toList()),
        isTrue,
      );
    }

    void testMessageWithExtendedOption(final CoapISpec spec, final int testNo) {
      final CoapMessage msg = CoapRequest(CoapCode.methodGET)
        ..id = 12345
        ..addOption(CoapOption.createVal(OptionType.contentFormat, 0));
      expect(msg.getFirstOption(OptionType.contentFormat)!.value, 0);
      msg.payload = typed.Uint8Buffer()..addAll('payload'.codeUnits);

      final data = spec.encode(msg)!;
      checkData(spec.name, data, testNo);
      final convMsg = spec.decode(data)!;

      expect(msg.code, convMsg.code);
      expect(msg.type, convMsg.type);
      expect(msg.id, convMsg.id);
      expect(msg.getAllOptions().length, convMsg.getAllOptions().length);
      expect(
        leq.equals(
          msg.getAllOptions().toList(),
          convMsg.getAllOptions().toList(),
        ),
        isTrue,
      );
      expect(convMsg.getFirstOption(OptionType.contentFormat)!.value, 0);
      expect(
        leq.equals(msg.payload!.toList(), convMsg.payload!.toList()),
        isTrue,
      );
    }

    void testRequestParsing(final CoapISpec spec, final int testNo) {
      final request = CoapRequest(CoapCode.methodPOST, confirmable: false)
        ..id = 7
        ..token = (typed.Uint8Buffer()..addAll(<int>[11, 82, 165, 77, 3]))
        ..addIfMatchOpaque(typed.Uint8Buffer()..addAll(<int>[34, 239]))
        ..addIfMatchOpaque(
          typed.Uint8Buffer()..addAll(<int>[88, 12, 254, 157, 5]),
        )
        ..contentType = 40
        ..accept = 40;

      final bytes = spec.encode(request)!;
      checkData(spec.name, bytes, testNo);
      final decoder = spec.newMessageDecoder(bytes);
      expect(decoder.isRequest, isTrue);

      final result = decoder.decodeRequest()!;
      expect(request.id, result.id);
      expect(
        leq.equals(request.token!.toList(), result.token!.toList()),
        isTrue,
      );
      expect(
        leq.equals(
          request.getAllOptions().toList(),
          result.getAllOptions().toList(),
        ),
        isTrue,
      );
    }

    void testResponseParsing(final CoapISpec spec, final int testNo) {
      final response = CoapResponse(CoapCode.content)
        ..type = CoapMessageType.non
        ..id = 9
        ..token = (typed.Uint8Buffer()..addAll(<int>[22, 255, 0, 78, 100, 22]))
        ..addETagOpaque(typed.Uint8Buffer()..addAll(<int>[1, 0, 0, 0, 0, 1]))
        ..addLocationPath('/one/two/three/four/five/six/seven/eight/nine/ten');

      final bytes = spec.encode(response)!;
      checkData(spec.name, bytes, testNo);

      final decoder = spec.newMessageDecoder(bytes);
      expect(decoder.isResponse, isTrue);

      final result = decoder.decodeResponse()!;
      expect(response.id, result.id);
      expect(
        leq.equals(response.token!.toList(), result.token!.toList()),
        isTrue,
      );
      expect(
        response.etags.toList().toString(),
        result.etags.toList().toString(),
      );
      expect(
        leq.equals(
          response.locationPaths.toList(),
          result.locationPaths.toList(),
        ),
        isTrue,
      );
    }

    test('Test RFC 7252', () {
      testMessage(CoapRfc7252(), 0);
      testMessageWithOptions(CoapRfc7252(), 1);
      testMessageWithExtendedOption(CoapRfc7252(), 2);
      testRequestParsing(CoapRfc7252(), 3);
      testResponseParsing(CoapRfc7252(), 4);
    });
  });
}
