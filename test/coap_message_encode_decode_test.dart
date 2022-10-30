// ignore_for_file: avoid_print

/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/04/2017
 * Copyright :  S.Hamblett
 */
import 'package:coap/coap.dart';
import 'package:coap/src/coap_message.dart';
import 'package:coap/src/codec/udp/message_decoder.dart';
import 'package:coap/src/codec/udp/message_encoder.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;

void main() {
  const leq = ListEquality<dynamic>();
  // ignore: unused_local_variable
  final DefaultCoapConfig conf = CoapConfigDefault();
  group('COAP All', () {
    final check = [
      <int>[64, 1, 48, 57, 255, 112, 97, 121, 108, 111, 97, 100],
      <int>[64, 1, 48, 57, 192, 33, 30, 255, 112, 97, 121, 108, 111, 97, 100],
      <int>[
        64,
        1,
        48,
        57,
        192,
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
        67,
        111,
        110,
        101,
        3,
        116,
        119,
        111,
        5,
        116,
        104,
        114,
        101,
        101,
        4,
        102,
        111,
        117,
        114,
        4,
        102,
        105,
        118,
        101,
        3,
        115,
        105,
        120,
        5,
        115,
        101,
        118,
        101,
        110,
        5,
        101,
        105,
        103,
        104,
        116,
        4,
        110,
        105,
        110,
        101,
        3,
        116,
        101,
        110
      ]
    ];

    /// Helper functions
    void printData(final List<int> data, final int testNo) {
      print('Test number is $testNo');
      print('Data is - $data');
      print('Chk  is - ${check[testNo]}');
    }

    void checkData(
      final typed.Uint8Buffer data,
      final int testNo,
    ) {
      printData(data.toList(), testNo);
      expect(data.toList().length, check[testNo].length);
      expect(leq.equals(data.toList(), check[testNo]), isTrue);
    }

    void testMessage(final int testNo) {
      final CoapMessage msg = CoapRequest(RequestMethod.get)
        ..id = 12345
        ..payload = (typed.Uint8Buffer()..addAll('payload'.codeUnits));
      final data = serializeUdpMessage(msg);
      checkData(data, testNo);
      final convMsg = deserializeUdpMessage(data);
      expect(msg.code, convMsg!.code);
      expect(msg.type, convMsg.type);
      expect(msg.id, convMsg.id);
      expect(msg.getAllOptions().length, convMsg.getAllOptions().length);
      expect(
        leq.equals(msg.payload!.toList(), convMsg.payload!.toList()),
        isTrue,
      );
      expect(msg.payloadString, convMsg.payloadString);
    }

    void testMessageWithOptions(final int testNo) {
      final CoapMessage msg = CoapRequest(RequestMethod.get)
        ..id = 12345
        ..payload = (typed.Uint8Buffer()..addAll('payload'.codeUnits))
        ..addOption(
          ContentFormatOption(CoapMediaType.textPlain.numericValue),
        )
        ..addOption(MaxAgeOption(30));
      expect(msg.getFirstOption<ContentFormatOption>()!.value, 0);
      expect(msg.getFirstOption<MaxAgeOption>()!.value, 30);
      final data = serializeUdpMessage(msg);
      checkData(data, testNo);
      final convMsg = deserializeUdpMessage(data);

      expect(msg.code, convMsg!.code);
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
        convMsg.getFirstOption<ContentFormatOption>()!.value,
        CoapMediaType.textPlain.numericValue,
      );
      expect(convMsg.getFirstOption<MaxAgeOption>()!.value, 30);
      expect(
        leq.equals(msg.payload!.toList(), convMsg.payload!.toList()),
        isTrue,
      );
    }

    void testMessageWithExtendedOption(final int testNo) {
      final CoapMessage msg = CoapRequest(RequestMethod.get)
        ..id = 12345
        ..addOption(ContentFormatOption(0));
      expect(msg.getFirstOption<ContentFormatOption>()!.value, 0);
      msg.payload = typed.Uint8Buffer()..addAll('payload'.codeUnits);

      final data = serializeUdpMessage(msg);
      checkData(data, testNo);
      final convMsg = deserializeUdpMessage(data);

      expect(msg.code, convMsg!.code);
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
      expect(convMsg.getFirstOption<ContentFormatOption>()!.value, 0);
      expect(
        leq.equals(msg.payload!.toList(), convMsg.payload!.toList()),
        isTrue,
      );
    }

    void testRequestParsing(final int testNo) {
      final request = CoapRequest(RequestMethod.post, confirmable: false)
        ..id = 7
        ..token = (typed.Uint8Buffer()..addAll(<int>[11, 82, 165, 77, 3]))
        ..addIfMatchOpaque(typed.Uint8Buffer()..addAll(<int>[34, 239]))
        ..addIfMatchOpaque(
          typed.Uint8Buffer()..addAll(<int>[88, 12, 254, 157, 5]),
        )
        ..contentType = CoapMediaType.fromIntValue(40)
        ..accept = CoapMediaType.fromIntValue(40);

      final bytes = serializeUdpMessage(request);
      checkData(bytes, testNo);
      final result = deserializeUdpMessage(bytes);
      expect(result!.isRequest, isTrue);

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

    void testResponseParsing(final int testNo) {
      final response = CoapResponse(
        ResponseCode.content,
        CoapMessageType.non,
      )
        ..id = 9
        ..token = (typed.Uint8Buffer()..addAll(<int>[22, 255, 0, 78, 100, 22]))
        ..addETagOpaque(typed.Uint8Buffer()..addAll(<int>[1, 0, 0, 0, 0, 1]))
        ..locationPath = '/one/two/three/four/five/six/seven/eight/nine/ten';

      final bytes = serializeUdpMessage(response);
      checkData(bytes, testNo);

      final message = deserializeUdpMessage(bytes);
      expect(message!.isResponse, isTrue);

      expect(response.id, message.id);
      expect(
        leq.equals(response.token!.toList(), message.token!.toList()),
        isTrue,
      );
      expect(
        response.etags.toList().toString(),
        message.etags.toList().toString(),
      );
      expect(
        leq.equals(
          response.locationPaths.toList(),
          message.locationPaths.toList(),
        ),
        isTrue,
      );
    }

    test('Test RFC 7252', () {
      testMessage(0);
      testMessageWithOptions(1);
      testMessageWithExtendedOption(2);
      testRequestParsing(3);
      testResponseParsing(4);
    });
  });
}
