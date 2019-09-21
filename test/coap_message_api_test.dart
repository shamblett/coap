/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 20/09/2019
 * Copyright :  S.Hamblett
 */
import 'dart:io';
import 'package:coap/coap.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart' as typed;
import 'package:collection/collection.dart';

void main() {
  // ignore: unused_local_variable
  final CoapConfig conf = CoapConfig(File('test/config_logging.yaml'));

  test('Construction', () {
    final CoapMessage message = CoapMessage();
    expect(message.type, CoapMessageType.unknown);
    expect(message.code, CoapCode.notSet);
    expect(message.id >= 1, isTrue);
    expect(message.id <= CoapMessage.initialIdLimit, isTrue);
    expect(message.resolveHost == 'localhost', isTrue);
    expect(message.optionMap.isEmpty, isTrue);
    expect(message.bindAddress, isNull);
    expect(message.token, isNull);
    expect(message.tokenString, isNull);
    expect(message.destination, isNull);
    expect(message.source, isNull);
    expect(message.isAcknowledged, isFalse);
    expect(message.acknowledgedHook, isNull);
    expect(message.isRejected, isFalse);
    expect(message.isTimedOut, isFalse);
    expect(message.timedOutHook, isNull);
  });

  test('Options', () {
    final CoapMessage message = CoapMessage();
    final CoapOption opt1 = CoapOption(optionTypeUriHost);
    final CoapOption opt2 = CoapOption(optionTypeReserved);
    final List<CoapOption> options = <CoapOption>[opt1, opt2];
    message.addOptions(options);
    expect(message.optionMap.length, 2);
    expect(message.getOptions(optionTypeUriHost).length, 1);
    expect(message.getOptions(optionTypeReserved).length, 1);
    message.setOption(opt1);
    message.setOption(opt2);
    expect(message.optionMap.length, 2);
    expect(message.getOptions(optionTypeUriHost).length, 1);
    expect(message.getOptions(optionTypeReserved).length, 1);
    message.setOptions(options);
    expect(message.optionMap.length, 2);
    expect(message.getOptions(optionTypeUriHost).length, 1);
    expect(message.getOptions(optionTypeReserved).length, 1);
    expect(message.getFirstOption(optionTypeReserved).type, optionTypeReserved);
    expect(message.getFirstOption(optionTypeUriHost).type, optionTypeUriHost);
    expect(message.getFirstOption(optionTypeUriPort), isNull);
    expect(message.hasOption(optionTypeUriHost), isTrue);
    expect(message.hasOption(optionTypeUriPort), isFalse);
    message.removeOptions(optionTypeUriHost);
    expect(message.optionMap.length, 1);
    expect(message.getOptions(optionTypeUriHost), isNull);
    expect(message.getOptions(optionTypeReserved).length, 1);
    message.removeOptions(optionTypeReserved);
    expect(message.optionMap.length, 0);
    expect(message.getOptions(optionTypeUriHost), isNull);
    expect(message.getOptions(optionTypeReserved), isNull);
  });

  test('Message codes', () {
    final CoapMessage message = CoapMessage();
    expect(message.isRequest, isFalse);
    expect(message.isResponse, isFalse);
    expect(message.isEmpty, isFalse);
    expect(message.isValid, isFalse);
    expect(message.codeString, 'Not Set');
  });

  test('Acknowledged', () {
    bool acked = false;
    void ackHook(){acked = true;}
    final CoapMessage message = CoapMessage();
    message.isAcknowledged = true;
    expect(message.isAcknowledged, isTrue);
    expect(acked, isFalse);
    final CoapEventBus eventBus = CoapEventBus();
    expect(eventBus.lastEvent is CoapAcknowledgedEvent, isTrue);
    eventBus.lastEvent = null;
    message.acknowledgedHook = ackHook;
    message.isAcknowledged = false;
    expect(message.isAcknowledged, isFalse);
    expect(acked, isTrue);
    expect(eventBus.lastEvent, isNull);
  });

  test('Rejected', () {
    final CoapMessage message = CoapMessage();
    message.isRejected = true;
    expect(message.isRejected, isTrue);
    final CoapEventBus eventBus = CoapEventBus();
    expect(eventBus.lastEvent is CoapRejectedEvent, isTrue);
  });

  test('Timed out', () {
    bool timedOut = false;
    void toHook(){timedOut = true;}
    final CoapMessage message = CoapMessage();
    message.isTimedOut = true;
    expect(message.isTimedOut, isTrue);
    expect(timedOut, isFalse);
    final CoapEventBus eventBus = CoapEventBus();
    expect(eventBus.lastEvent is CoapTimedOutEvent, isTrue);
    eventBus.lastEvent = null;
    message.timedOutHook = toHook;
    message.isTimedOut = false;
    expect(message.isTimedOut, isFalse);
    expect(timedOut, isTrue);
    expect(eventBus.lastEvent, isNull);
  });

}
