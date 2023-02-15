/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 18/05/2018
 * Copyright :  S.Hamblett
 */

import 'package:coap/coap.dart';
import 'package:coap/src/coap_message.dart';
import 'package:coap/src/codec/udp/datagram_reader.dart';
import 'package:coap/src/codec/udp/datagram_writer.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;

void main() {
  const leq = ListEquality<dynamic>();
  // ignore: unused_local_variable
  final DefaultCoapConfig conf = CoapConfigDefault();

  test('Test32BitInt', () {
    const intIn = 0x87654321;

    final writer = DatagramWriter()..write(intIn, 32);

    final reader = DatagramReader(writer.toByteArray());
    final intOut = reader.read(32);

    expect(intIn, intOut);
  });
  test('Test32BitIntZero', () {
    const intIn = 0;

    final writer = DatagramWriter()..write(intIn, 32);

    final reader = DatagramReader(writer.toByteArray());
    final intOut = reader.read(32);

    expect(intIn, intOut);
  });
  test('Test32BitInt1', () {
    const intIn = 0xFFFFFFFF;

    final writer = DatagramWriter()..write(intIn, 32);

    final reader = DatagramReader(writer.toByteArray());
    final intOut = reader.read(32);

    expect(intIn, intOut);
  });
  test('Test16BitInt', () {
    const intIn = 0x00004321;

    final writer = DatagramWriter()..write(intIn, 16);

    final reader = DatagramReader(writer.toByteArray());
    final intOut = reader.read(16);

    expect(intIn, intOut);
  });
  test('Test8BitInt', () {
    const intIn = 0x00000021;

    final writer = DatagramWriter()..write(intIn, 8);

    final reader = DatagramReader(writer.toByteArray());
    final intOut = reader.read(8);

    expect(intIn, intOut);
  });

  test('Test4BitInt', () {
    const intIn = 0x00000005;

    final writer = DatagramWriter()..write(intIn, 4);

    final reader = DatagramReader(writer.toByteArray());
    final intOut = reader.read(4);

    expect(intIn, intOut);
  });
  test('Test2BitInt', () {
    const intIn = 0x00000002;

    final writer = DatagramWriter()..write(intIn, 2);

    final reader = DatagramReader(writer.toByteArray());
    final intOut = reader.read(2);

    expect(intIn, intOut);
  });
  test('Test1BitInt', () {
    const intIn = 0x00000001;

    final writer = DatagramWriter()..write(intIn, 1);

    final reader = DatagramReader(writer.toByteArray());
    final intOut = reader.read(1);

    expect(intIn, intOut);
  });
  test('TestAlignedBytes', () {
    final bytesIn = typed.Uint8Buffer()..addAll('Some aligned bytes'.codeUnits);

    final writer = DatagramWriter()..writeBytes(bytesIn);

    final reader = DatagramReader(writer.toByteArray());
    final bytesOut = reader.readBytesLeft();

    expect(leq.equals(bytesIn.toList(), bytesOut.toList()), isTrue);
  });
  test('TestUnalignedBytes1', () {
    const bitCount = 1;
    const bitsIn = 0x1;
    final bytesIn = typed.Uint8Buffer()..addAll('Some aligned bytes'.codeUnits);

    final writer = DatagramWriter()
      ..write(bitsIn, bitCount)
      ..writeBytes(bytesIn);

    final reader = DatagramReader(writer.toByteArray());
    final bitsOut = reader.read(bitCount);
    final bytesOut = reader.readBytes(bytesIn.length);

    expect(bitsIn, bitsOut);
    expect(leq.equals(bytesIn.toList(), bytesOut.toList()), isTrue);
  });
  test('TestUnalignedBytes3', () {
    const bitCount = 3;
    const bitsIn = 0x5;
    final bytesIn = typed.Uint8Buffer()..addAll('Some aligned bytes'.codeUnits);

    final writer = DatagramWriter()
      ..write(bitsIn, bitCount)
      ..writeBytes(bytesIn);

    final reader = DatagramReader(writer.toByteArray());
    final bitsOut = reader.read(bitCount);
    final bytesOut = reader.readBytes(bytesIn.length);

    expect(bitsIn, bitsOut);
    expect(leq.equals(bytesIn.toList(), bytesOut.toList()), isTrue);
  });
  test('TestUnalignedBytes7', () {
    const bitCount = 7;
    const bitsIn = 0x69;
    final bytesIn = typed.Uint8Buffer()..addAll('Some aligned bytes'.codeUnits);

    final writer = DatagramWriter()
      ..write(bitsIn, bitCount)
      ..writeBytes(bytesIn);

    final reader = DatagramReader(writer.toByteArray());
    final bitsOut = reader.read(bitCount);
    final bytesOut = reader.readBytes(bytesIn.length);

    expect(bitsIn, bitsOut);
    expect(leq.equals(bytesIn.toList(), bytesOut.toList()), isTrue);
  });
  test('TestBytesLeft', () {
    const bitCount = 8;
    const bitsIn = 0xaa;
    final bytesIn = typed.Uint8Buffer()..addAll('Some aligned bytes'.codeUnits);

    final writer = DatagramWriter()
      ..write(bitsIn, bitCount)
      ..writeBytes(bytesIn);

    final reader = DatagramReader(writer.toByteArray());
    final bitsOut = reader.read(bitCount);
    final bytesOut = reader.readBytes(bytesIn.length);

    expect(bitsIn, bitsOut);
    expect(leq.equals(bytesIn.toList(), bytesOut.toList()), isTrue);
  });
  test('TestBytesLeftUnaligned', () {
    const bitCount = 7;
    const bitsIn = 0x55;
    final bytesIn = typed.Uint8Buffer()..addAll('Some aligned bytes'.codeUnits);

    final writer = DatagramWriter()
      ..write(bitsIn, bitCount)
      ..writeBytes(bytesIn);

    final reader = DatagramReader(writer.toByteArray());
    final bitsOut = reader.read(bitCount);
    final bytesOut = reader.readBytes(bytesIn.length);

    expect(bitsIn, bitsOut);
    expect(leq.equals(bytesIn.toList(), bytesOut.toList()), isTrue);
  });
  test('TestGETRequestHeader', () {
    const versionIn = 1;
    const versionSz = 2;
    const typeIn = 0; // Confirmable
    const typeSz = 2;
    const optionCntIn = 1;
    const optionCntSz = 4;
    const codeIn = 1; // GET Request
    const codeSz = 8;
    const msgIdIn = 0x1234;
    const msgIdSz = 16;

    final writer = DatagramWriter()
      ..write(versionIn, versionSz)
      ..write(typeIn, typeSz)
      ..write(optionCntIn, optionCntSz)
      ..write(codeIn, codeSz)
      ..write(msgIdIn, msgIdSz);

    final data = writer.toByteArray();
    final dataRef = typed.Uint8Buffer()..addAll(<int>[0x41, 0x01, 0x12, 0x34]);

    expect(leq.equals(dataRef.toList(), data.toList()), isTrue);

    final reader = DatagramReader(data);
    final versionOut = reader.read(versionSz);
    final typeOut = reader.read(typeSz);
    final optionCntOut = reader.read(optionCntSz);
    final codeOut = reader.read(codeSz);
    final msgIdOut = reader.read(msgIdSz);

    expect(versionIn, versionOut);
    expect(typeIn, typeOut);
    expect(optionCntIn, optionCntOut);
    expect(codeIn, codeOut);
    expect(msgIdIn, msgIdOut);
  });

  test('Extended Token Length', () {
    const leq = ListEquality<int>();

    for (final tokenLength in [200, 500]) {
      final token = (typed.Uint8Buffer()
        ..addAll(
          List<int>.generate(tokenLength, ((final index) => index % 256)),
        ));
      final request =
          CoapRequest(Uri.parse('coap://example.org'), RequestMethod.get)
            ..id = 5
            ..token = token;

      final payload = request.toUdpPayload();
      expect(
        leq.equals(
          CoapMessage.fromUdpPayload(payload, 'coap')?.token?.toList(),
          token,
        ),
        isTrue,
      );
    }
  });
}
