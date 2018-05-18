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
import 'dart:convert';
import 'dart:math';

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

    CoapDatagramReader reader = new CoapDatagramReader(writer.toByteArray());
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
}
