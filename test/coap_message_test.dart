/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/04/2017
 * Copyright :  S.Hamblett
 */
import 'package:coap/coap.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'package:log4dart/log4dart_vm.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:io';

void main() {
  /// Helper functions
  void testMessage(CoapISpec spec) {
    CoapMessage msg = new CoapRequest.isConfirmable(CoapCode.methodGET, true);

    msg.id = 12345;
    msg.payloadString = "payload";
    typed.Uint8Buffer data = spec.encode(msg);
    CoapMessage convMsg = spec.decode(data);
    expect(msg.code, convMsg.code);
    expect(msg.type, convMsg.type);
    expect(msg.id, convMsg.id);
    expect(msg
        .getSortedOptions()
        .length, convMsg
        .getSortedOptions()
        .length);
    expect(msg.payload == convMsg.payload, isTrue);
  }


  group("COAP All", () {
    test('TestDraft03', () {
      testMessage(CoAP.Spec.Draft03);
    });

  });
}
