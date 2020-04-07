/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 18/05/2018
 * Copyright :  S.Hamblett
 */

import 'package:coap/coap.dart';
import 'package:coap/config/coap_config_logging.dart';
import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;

// ignore_for_file: omit_local_variable_types
// ignore_for_file: unnecessary_final
// ignore_for_file: cascade_invocations
// ignore_for_file: avoid_annotating_with_dynamic
// ignore_for_file: avoid_types_on_closure_parameters
// ignore_for_file: flutter_style_todos

void main() {
  const ListEquality<dynamic> leq = ListEquality<dynamic>();
  // ignore: unused_local_variable
  final DefaultCoapConfig conf = CoapConfigLogging();

  test('Test32BitInt', () {
    const int intIn = 0x87654321;

    final CoapDatagramWriter writer = CoapDatagramWriter();
    writer.write(intIn, 32);

    final CoapDatagramReader reader = CoapDatagramReader(writer.toByteArray());
    final int intOut = reader.read(32);

    expect(intIn, intOut);
  });
  test('Test32BitIntZero', () {
    const int intIn = 0;

    final CoapDatagramWriter writer = CoapDatagramWriter();
    writer.write(intIn, 32);

    final CoapDatagramReader reader = CoapDatagramReader(writer.toByteArray());
    final int intOut = reader.read(32);

    expect(intIn, intOut);
  });
  test('Test32BitInt1', () {
    const int intIn = 0xFFFFFFFF;

    final CoapDatagramWriter writer = CoapDatagramWriter();
    writer.write(intIn, 32);

    final CoapDatagramReader reader = CoapDatagramReader(writer.toByteArray());
    final int intOut = reader.read(32);

    expect(intIn, intOut);
  });
  test('Test16BitInt', () {
    const int intIn = 0x00004321;

    final CoapDatagramWriter writer = CoapDatagramWriter();
    writer.write(intIn, 16);

    final CoapDatagramReader reader = CoapDatagramReader(writer.toByteArray());
    final int intOut = reader.read(16);

    expect(intIn, intOut);
  });
  test('Test8BitInt', () {
    const int intIn = 0x00000021;

    final CoapDatagramWriter writer = CoapDatagramWriter();
    writer.write(intIn, 8);

    final CoapDatagramReader reader = CoapDatagramReader(writer.toByteArray());
    final int intOut = reader.read(8);

    expect(intIn, intOut);
  });

  test('Test4BitInt', () {
    const int intIn = 0x00000005;

    final CoapDatagramWriter writer = CoapDatagramWriter();
    writer.write(intIn, 4);

    final CoapDatagramReader reader = CoapDatagramReader(writer.toByteArray());
    final int intOut = reader.read(4);

    expect(intIn, intOut);
  });
  test('Test2BitInt', () {
    const int intIn = 0x00000002;

    final CoapDatagramWriter writer = CoapDatagramWriter();
    writer.write(intIn, 2);

    final CoapDatagramReader reader = CoapDatagramReader(writer.toByteArray());
    final int intOut = reader.read(2);

    expect(intIn, intOut);
  });
  test('Test1BitInt', () {
    const int intIn = 0x00000001;

    final CoapDatagramWriter writer = CoapDatagramWriter();
    writer.write(intIn, 1);

    final CoapDatagramReader reader = CoapDatagramReader(writer.toByteArray());
    final int intOut = reader.read(1);

    expect(intIn, intOut);
  });
  test('TestAlignedBytes', () {
    final typed.Uint8Buffer bytesIn = typed.Uint8Buffer()
      ..addAll('Some aligned bytes'.codeUnits);

    final CoapDatagramWriter writer = CoapDatagramWriter();
    writer.writeBytes(bytesIn);

    final CoapDatagramReader reader = CoapDatagramReader(writer.toByteArray());
    final typed.Uint8Buffer bytesOut = reader.readBytesLeft();

    expect(leq.equals(bytesIn.toList(), bytesOut.toList()), isTrue);
  });
  test('TestUnalignedBytes1', () {
    const int bitCount = 1;
    const int bitsIn = 0x1;
    final typed.Uint8Buffer bytesIn = typed.Uint8Buffer()
      ..addAll('Some aligned bytes'.codeUnits);

    final CoapDatagramWriter writer = CoapDatagramWriter();
    writer.write(bitsIn, bitCount);
    writer.writeBytes(bytesIn);

    final CoapDatagramReader reader = CoapDatagramReader(writer.toByteArray());
    final int bitsOut = reader.read(bitCount);
    final typed.Uint8Buffer bytesOut = reader.readBytes(bytesIn.length);

    expect(bitsIn, bitsOut);
    expect(leq.equals(bytesIn.toList(), bytesOut.toList()), isTrue);
  });
  test('TestUnalignedBytes3', () {
    const int bitCount = 3;
    const int bitsIn = 0x5;
    final typed.Uint8Buffer bytesIn = typed.Uint8Buffer()
      ..addAll('Some aligned bytes'.codeUnits);

    final CoapDatagramWriter writer = CoapDatagramWriter();
    writer.write(bitsIn, bitCount);
    writer.writeBytes(bytesIn);

    final CoapDatagramReader reader = CoapDatagramReader(writer.toByteArray());
    final int bitsOut = reader.read(bitCount);
    final typed.Uint8Buffer bytesOut = reader.readBytes(bytesIn.length);

    expect(bitsIn, bitsOut);
    expect(leq.equals(bytesIn.toList(), bytesOut.toList()), isTrue);
  });
  test('TestUnalignedBytes7', () {
    const int bitCount = 7;
    const int bitsIn = 0x69;
    final typed.Uint8Buffer bytesIn = typed.Uint8Buffer()
      ..addAll('Some aligned bytes'.codeUnits);

    final CoapDatagramWriter writer = CoapDatagramWriter();
    writer.write(bitsIn, bitCount);
    writer.writeBytes(bytesIn);

    final CoapDatagramReader reader = CoapDatagramReader(writer.toByteArray());
    final int bitsOut = reader.read(bitCount);
    final typed.Uint8Buffer bytesOut = reader.readBytes(bytesIn.length);

    expect(bitsIn, bitsOut);
    expect(leq.equals(bytesIn.toList(), bytesOut.toList()), isTrue);
  });
  test('TestBytesLeft', () {
    const int bitCount = 8;
    const int bitsIn = 0xaa;
    final typed.Uint8Buffer bytesIn = typed.Uint8Buffer()
      ..addAll('Some aligned bytes'.codeUnits);

    final CoapDatagramWriter writer = CoapDatagramWriter();
    writer.write(bitsIn, bitCount);
    writer.writeBytes(bytesIn);

    final CoapDatagramReader reader = CoapDatagramReader(writer.toByteArray());
    final int bitsOut = reader.read(bitCount);
    final typed.Uint8Buffer bytesOut = reader.readBytes(bytesIn.length);

    expect(bitsIn, bitsOut);
    expect(leq.equals(bytesIn.toList(), bytesOut.toList()), isTrue);
  });
  test('TestBytesLeftUnaligned', () {
    const int bitCount = 7;
    const int bitsIn = 0x55;
    final typed.Uint8Buffer bytesIn = typed.Uint8Buffer()
      ..addAll('Some aligned bytes'.codeUnits);

    final CoapDatagramWriter writer = CoapDatagramWriter();
    writer.write(bitsIn, bitCount);
    writer.writeBytes(bytesIn);

    final CoapDatagramReader reader = CoapDatagramReader(writer.toByteArray());
    final int bitsOut = reader.read(bitCount);
    final typed.Uint8Buffer bytesOut = reader.readBytes(bytesIn.length);

    expect(bitsIn, bitsOut);
    expect(leq.equals(bytesIn.toList(), bytesOut.toList()), isTrue);
  });
  test('TestGETRequestHeader', () {
    const int versionIn = 1;
    const int versionSz = 2;
    const int typeIn = 0; // Confirmable
    const int typeSz = 2;
    const int optionCntIn = 1;
    const int optionCntSz = 4;
    const int codeIn = 1; // GET Request
    const int codeSz = 8;
    const int msgIdIn = 0x1234;
    const int msgIdSz = 16;

    final CoapDatagramWriter writer = CoapDatagramWriter();
    writer.write(versionIn, versionSz);
    writer.write(typeIn, typeSz);
    writer.write(optionCntIn, optionCntSz);
    writer.write(codeIn, codeSz);
    writer.write(msgIdIn, msgIdSz);

    final typed.Uint8Buffer data = writer.toByteArray();
    final typed.Uint8Buffer dataRef = typed.Uint8Buffer()
      ..addAll(<int>[0x41, 0x01, 0x12, 0x34]);

    expect(leq.equals(dataRef.toList(), data.toList()), isTrue);

    final CoapDatagramReader reader = CoapDatagramReader(data);
    final int versionOut = reader.read(versionSz);
    final int typeOut = reader.read(typeSz);
    final int optionCntOut = reader.read(optionCntSz);
    final int codeOut = reader.read(codeSz);
    final int msgIdOut = reader.read(msgIdSz);

    expect(versionIn, versionOut);
    expect(typeIn, typeOut);
    expect(optionCntIn, optionCntOut);
    expect(codeIn, codeOut);
    expect(msgIdIn, msgIdOut);
  });
}
