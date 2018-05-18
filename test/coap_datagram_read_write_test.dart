/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 18/05/2018
 * Copyright :  S.Hamblett
 */
import 'package:coap/coap.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'dart:convert';
import 'dart:math';

void main() {
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
}
