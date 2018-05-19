/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 18/05/2018
 * Copyright :  S.Hamblett
 */
import 'package:coap/coap.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'package:collection/equality.dart';

void main() {
  final ListEquality leq = new ListEquality();

  test('Test32BitInt', () {
    final int intIn = 0x87654321;

    final CoapDatagramWriter writer = new CoapDatagramWriter();
    writer.write(intIn, 32);

    final CoapDatagramReader reader =
    new CoapDatagramReader(writer.toByteArray());
    final int intOut = reader.read(32);

    expect(intIn, intOut);
  });
  test('Test32BitIntZero', () {
    final int intIn = 0;

    final CoapDatagramWriter writer = new CoapDatagramWriter();
    writer.write(intIn, 32);

    final CoapDatagramReader reader =
    new CoapDatagramReader(writer.toByteArray());
    final int intOut = reader.read(32);

    expect(intIn, intOut);
  });
  test('Test32BitInt1', () {
    final int intIn = 0xFFFFFFFF;

    final CoapDatagramWriter writer = new CoapDatagramWriter();
    writer.write(intIn, 32);

    final CoapDatagramReader reader =
    new CoapDatagramReader(writer.toByteArray());
    final int intOut = reader.read(32);

    expect(intIn, intOut);
  });
  test('Test16BitInt', () {
    final int intIn = 0x00004321;

    final CoapDatagramWriter writer = new CoapDatagramWriter();
    writer.write(intIn, 16);

    final CoapDatagramReader reader =
    new CoapDatagramReader(writer.toByteArray());
    final int intOut = reader.read(16);

    expect(intIn, intOut);
  });
  test('Test8BitInt', () {
    final int intIn = 0x00000021;

    final CoapDatagramWriter writer = new CoapDatagramWriter();
    writer.write(intIn, 8);

    final CoapDatagramReader reader =
    new CoapDatagramReader(writer.toByteArray());
    final int intOut = reader.read(8);

    expect(intIn, intOut);
  });

  test('Test4BitInt', () {
    final int intIn = 0x00000005;

    final CoapDatagramWriter writer = new CoapDatagramWriter();
    writer.write(intIn, 4);

    final CoapDatagramReader reader =
    new CoapDatagramReader(writer.toByteArray());
    final int intOut = reader.read(4);

    expect(intIn, intOut);
  });
  test('Test2BitInt', () {
    final int intIn = 0x00000002;

    final CoapDatagramWriter writer = new CoapDatagramWriter();
    writer.write(intIn, 2);

    final CoapDatagramReader reader =
    new CoapDatagramReader(writer.toByteArray());
    final int intOut = reader.read(2);

    expect(intIn, intOut);
  });
  test('Test1BitInt', () {
    final int intIn = 0x00000001;

    final CoapDatagramWriter writer = new CoapDatagramWriter();
    writer.write(intIn, 1);

    final CoapDatagramReader reader =
    new CoapDatagramReader(writer.toByteArray());
    final int intOut = reader.read(1);

    expect(intIn, intOut);
  });
  test('TestAlignedBytes', () {
    final typed.Uint8Buffer bytesIn = new typed.Uint8Buffer()
      ..addAll("Some aligned bytes".codeUnits);

    final CoapDatagramWriter writer = new CoapDatagramWriter();
    writer.writeBytes(bytesIn);

    final CoapDatagramReader reader =
    new CoapDatagramReader(writer.toByteArray());
    final typed.Uint8Buffer bytesOut = reader.readBytesLeft();

    expect(leq.equals(bytesIn.toList(), bytesOut.toList()), isTrue);
  });
  test('TestUnalignedBytes1', () {
    final int bitCount = 1;
    final int bitsIn = 0x1;
    final typed.Uint8Buffer bytesIn = new typed.Uint8Buffer()
      ..addAll("Some aligned bytes".codeUnits);

    final CoapDatagramWriter writer = new CoapDatagramWriter();
    writer.write(bitsIn, bitCount);
    writer.writeBytes(bytesIn);

    final CoapDatagramReader reader =
    new CoapDatagramReader(writer.toByteArray());
    final int bitsOut = reader.read(bitCount);
    final typed.Uint8Buffer bytesOut = reader.readBytes(bytesIn.length);

    expect(bitsIn, bitsOut);
    expect(leq.equals(bytesIn.toList(), bytesOut.toList()), isTrue);
  });
  test('TestUnalignedBytes3', () {
    final int bitCount = 3;
    final int bitsIn = 0x5;
    final typed.Uint8Buffer bytesIn = new typed.Uint8Buffer()
      ..addAll("Some aligned bytes".codeUnits);

    final CoapDatagramWriter writer = new CoapDatagramWriter();
    writer.write(bitsIn, bitCount);
    writer.writeBytes(bytesIn);

    final CoapDatagramReader reader =
    new CoapDatagramReader(writer.toByteArray());
    final int bitsOut = reader.read(bitCount);
    final typed.Uint8Buffer bytesOut = reader.readBytes(bytesIn.length);

    expect(bitsIn, bitsOut);
    expect(leq.equals(bytesIn.toList(), bytesOut.toList()), isTrue);
  });
  test('TestUnalignedBytes7', () {
    final int bitCount = 7;
    final int bitsIn = 0x69;
    final typed.Uint8Buffer bytesIn = new typed.Uint8Buffer()
      ..addAll("Some aligned bytes".codeUnits);

    final CoapDatagramWriter writer = new CoapDatagramWriter();
    writer.write(bitsIn, bitCount);
    writer.writeBytes(bytesIn);

    final CoapDatagramReader reader =
    new CoapDatagramReader(writer.toByteArray());
    final int bitsOut = reader.read(bitCount);
    final typed.Uint8Buffer bytesOut = reader.readBytes(bytesIn.length);

    expect(bitsIn, bitsOut);
    expect(leq.equals(bytesIn.toList(), bytesOut.toList()), isTrue);
  });
  test('TestBytesLeft', () {
    final int bitCount = 8;
    final int bitsIn = 0xaa;
    final typed.Uint8Buffer bytesIn = new typed.Uint8Buffer()
      ..addAll("Some aligned bytes".codeUnits);

    final CoapDatagramWriter writer = new CoapDatagramWriter();
    writer.write(bitsIn, bitCount);
    writer.writeBytes(bytesIn);

    final CoapDatagramReader reader =
    new CoapDatagramReader(writer.toByteArray());
    final int bitsOut = reader.read(bitCount);
    final typed.Uint8Buffer bytesOut = reader.readBytes(bytesIn.length);

    expect(bitsIn, bitsOut);
    expect(leq.equals(bytesIn.toList(), bytesOut.toList()), isTrue);
  });
  test('TestBytesLeftUnaligned', () {
    final int bitCount = 7;
    final int bitsIn = 0x55;
    final typed.Uint8Buffer bytesIn = new typed.Uint8Buffer()
      ..addAll("Some aligned bytes".codeUnits);

    final CoapDatagramWriter writer = new CoapDatagramWriter();
    writer.write(bitsIn, bitCount);
    writer.writeBytes(bytesIn);

    final CoapDatagramReader reader =
    new CoapDatagramReader(writer.toByteArray());
    final int bitsOut = reader.read(bitCount);
    final typed.Uint8Buffer bytesOut = reader.readBytes(bytesIn.length);

    expect(bitsIn, bitsOut);
    expect(leq.equals(bytesIn.toList(), bytesOut.toList()), isTrue);
  });
  test('TestGETRequestHeader', () {
    final int versionIn = 1;
    final int versionSz = 2;
    final int typeIn = 0; // Confirmable
    final int typeSz = 2;
    final int optionCntIn = 1;
    final int optionCntSz = 4;
    final int codeIn = 1; // GET Request
    final int codeSz = 8;
    final int msgIdIn = 0x1234;
    final int msgIdSz = 16;

    final CoapDatagramWriter writer = new CoapDatagramWriter();
    writer.write(versionIn, versionSz);
    writer.write(typeIn, typeSz);
    writer.write(optionCntIn, optionCntSz);
    writer.write(codeIn, codeSz);
    writer.write(msgIdIn, msgIdSz);

    final typed.Uint8Buffer data = writer.toByteArray();
    final typed.Uint8Buffer dataRef = new typed.Uint8Buffer()
      ..addAll([0x41, 0x01, 0x12, 0x34]);

    expect(leq.equals(dataRef.toList(), data.toList()), isTrue);

    final CoapDatagramReader reader = new CoapDatagramReader(data);
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
