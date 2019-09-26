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

// Note that nnot all API methods are tested here, some are tested in other unit test suites,
// some in dynamic testing.
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
    expect(message.retransmittingHook, isNull);
    expect(message.isCancelled, isFalse);
    expect(message.duplicate, isFalse);
    expect(message.timestamp, isNull);
    expect(message.maxRetransmit, 0);
    expect(message.ackTimeout, 0);
    expect(message.payload, isNull);
    expect(message.payloadSize, 0);
    expect(message.payloadString, isNull);
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
    message.addOptions(options);
    expect(message.optionMap.length, 2);
    final CoapOption opt3 = CoapOption(optionTypeUriHost);
    message.addOption(opt3);
    expect(message.optionMap.length, 2);
    expect(message
        .getOptions(optionTypeUriHost)
        .length, 2);
    final bool ret = message.removeOption(opt1);
    expect(ret, isTrue);
    expect(message
        .getOptions(optionTypeUriHost)
        .length, 1);
    expect(message.getOptions(optionTypeUriHost).toList()[0] == opt3, isTrue);
    message.clearOptions();
    expect(message.optionMap.length, 0);
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
    void ackHook() {
      acked = true;
    }

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
    void toHook() {
      timedOut = true;
    }

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

  test('Retransmitting', () {
    final CoapMessage message = CoapMessage();
    bool retrans = false;
    void retransHook() {
      retrans = true;
    }

    message.fireRetransmitting();
    expect(retrans, isFalse);
    message.retransmittingHook = retransHook;
    message.fireRetransmitting();
    expect(retrans, isTrue);
  });

  test('Cancelled', () {
    final CoapMessage message = CoapMessage();
    message.isCancelled = true;
    expect(message.isCancelled, isTrue);
    final CoapEventBus eventBus = CoapEventBus();
    expect(eventBus.lastEvent is CoapCancelledEvent, isTrue);
    message.isCancelled = false;
    message.cancel();
    expect(message.isCancelled, isTrue);
  });

  test('Payload', () {
    final CoapMessage message = CoapMessage();
    message.setPayload('This is the payload');
    expect(message.payload, isNotNull);
    expect(message.payloadString, 'This is the payload');
    expect(message.payloadSize, 19);
  });

  test('If match', () {
    final CoapMessage message = CoapMessage();
    expect(message.ifMatches.length, 0);
    message.addIfMatch('ETag-1').addIfMatch('ETag-2');
    expect(message.ifMatches.length, 2);
    expect(message.ifMatches.toList()[0].stringValue, 'ETag-1');
    expect(message.ifMatches.toList()[1].stringValue, 'ETag-2');
    message.removeIfMatchOpaque(message.ifMatches.toList()[0].valueBytes);
    expect(message.ifMatches.length, 1);
    expect(message.ifMatches.toList()[0].stringValue, 'ETag-2');
    message.clearIfMatches();
    expect(message.ifMatches.length, 0);
    final CoapOption opt1 = CoapOption(optionTypeUriHost);
    expect(() => message.removeIfMatch(opt1), throwsArgumentError);
    final CoapOption opt2 = CoapOption(optionTypeIfMatch);
    opt2.stringValue = 'ETag-3';
    message.addOption(opt2);
    expect(message.ifMatches.length, 1);
    message.removeIfMatch(opt2);
    expect(message.ifMatches.length, 0);
  });

  test('ETags', () {
    final CoapMessage message = CoapMessage();
    expect(message.etags.length, 0);
    final CoapOption none = CoapOption(optionTypeIfMatch);
    final CoapOption etag1 = CoapOption(optionTypeETag);
    etag1.stringValue = 'Etag-1';
    final CoapOption etag2 = CoapOption(optionTypeETag);
    etag2.stringValue = 'Etag-2';
    expect(() => message.addEtag(none), throwsArgumentError);
    message.addEtag(etag1);
    expect(message.etags.length, 1);
    message.addETagOpaque(etag2.valueBytes);
    expect(message.etags.length, 2);
    message.removeETagOpaque(etag2.valueBytes);
    expect(message.etags.length, 1);
    expect(message.etags.toList()[0] == etag1, isTrue);
    message.clearETags();
    expect(message.etags.length, 0);
    message.addEtag(etag1);
    expect(message.etags.length, 1);
    expect(() => message.removeEtag(none), throwsArgumentError);
    final bool ret = message.removeEtag(etag1);
    expect(ret, isTrue);
    expect(message.etags.length, 0);
  });

  test('If None match', () {
    final CoapMessage message = CoapMessage();
    expect(message.ifNoneMatches.length, 0);
    final CoapOption none = CoapOption(optionTypeIfMatch);
    final CoapOption inm1 = CoapOption(optionTypeIfNoneMatch);
    inm1.stringValue = 'Inm1';
    final CoapOption inm2 = CoapOption(optionTypeIfNoneMatch);
    inm2.stringValue = 'Inm2';
    message.addIfNoneMatch(inm1).addIfNoneMatch(inm2);
    expect(message.ifNoneMatches.length, 2);
    expect(() => message.addIfNoneMatch(none), throwsArgumentError);
    final CoapOption inm3 = CoapOption(optionTypeIfNoneMatch);
    inm3.stringValue = 'Inm3';
    message.addIfNoneMatchOpaque(inm3.valueBytes);
    expect(message.ifNoneMatches.length, 3);
    message.removeIfNoneMatchOpaque(inm2.valueBytes);
    expect(message.ifNoneMatches.length, 2);
    expect(() => message.removeIfNoneMatch(none), throwsArgumentError);
    message.clearIfNoneMatches();
    expect(message.ifNoneMatches.length, 0);
  });

  test('Uri path', () {
    final CoapMessage message = CoapMessage();
    expect(message.uriPaths.length, 0);
    message.uriPath = 'a/uri/path/';
    expect(message.uriPaths.length, 3);
    expect(message.uriPathsString, 'a/uri/path');
    message.addUriPath('longer');
    expect(message.uriPaths.length, 4);
    expect(message.uriPathsString, 'a/uri/path/longer');
    expect(() => message.addUriPath(null), throwsArgumentError);
    const String tolong =
        'nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn'
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
        'nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn';
    expect(() => message.addUriPath(tolong), throwsArgumentError);
    message.removeUriPath('path');
    expect(message.uriPaths.length, 3);
    expect(message.uriPathsString, 'a/uri/longer');
    message.clearUriPath();
    expect(message.uriPaths.length, 0);
  });

  test('Uri query', () {
    final CoapMessage message = CoapMessage();
    expect(message.uriQueries.length, 0);
  });
}
