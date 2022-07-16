/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 20/09/2019
 * Copyright :  S.Hamblett
 */

import 'package:coap/coap.dart';
import 'package:coap/src/coap_empty_message.dart';
import 'package:coap/src/event/coap_event_bus.dart';
import 'package:test/test.dart';

// Note that not all API methods are tested here, some are tested in other unit
// test suites, some in dynamic testing.
void main() {
  // ignore: unused_local_variable
  final DefaultCoapConfig conf = CoapConfigDefault();

  test('Construction', () {
    final message = CoapEmptyMessage(CoapMessageType.con);
    expect(message.type, CoapMessageType.con);
    expect(message.id, null);
    expect(message.resolveHost, 'localhost');
    expect(message.optionMap.isEmpty, isTrue);
    expect(message.bindAddress, isNull);
    expect(message.token, isNull);
    expect(message.tokenString, '');
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
    final message = CoapRequest(CoapCode.get);
    final opt1 = CoapOption(OptionType.uriHost);
    expect(
      () => CoapOption.create(OptionType.fromTypeNumber(9000)),
      throwsA(const TypeMatcher<UnknownElectiveOptionException>()),
    );
    expect(
      () => CoapOption.create(OptionType.fromTypeNumber(9001)),
      throwsA(const TypeMatcher<UnknownCriticalOptionException>()),
    );
    final options = <CoapOption>[
      opt1,
    ];
    message.addOptions(options);
    expect(message.optionMap.length, 1);
    expect(message.getOptions(OptionType.uriHost)!.length, 1);
    message.setOption(opt1);
    expect(message.optionMap.length, 1);
    expect(message.getOptions(OptionType.uriHost)!.length, 1);
    message.setOptions(options);
    expect(message.optionMap.length, 1);
    expect(message.getOptions(OptionType.uriHost)!.length, 1);
    expect(
      message.getFirstOption(OptionType.uriHost)!.type,
      OptionType.uriHost,
    );
    expect(message.getFirstOption(OptionType.uriPort), isNull);
    expect(message.hasOption(OptionType.uriHost), isTrue);
    expect(message.hasOption(OptionType.uriPort), isFalse);
    message.removeOptions(OptionType.uriHost);
    expect(message.optionMap.length, 0);
    expect(message.getOptions(OptionType.uriHost), isNull);
    expect(message.optionMap.length, 0);
    expect(message.getOptions(OptionType.uriHost), isNull);
    message.addOptions(options);
    expect(message.optionMap.length, 1);
    final opt2 = CoapOption(OptionType.uriHost);
    message.addOption(opt2);
    expect(message.optionMap.length, 1);
    expect(message.getOptions(OptionType.uriHost)!.length, 2);
    final ret = message.removeOption(opt1);
    expect(ret, isTrue);
    expect(message.getOptions(OptionType.uriHost)!.length, 1);
    expect(message.getOptions(OptionType.uriHost)!.toList()[0] == opt2, isTrue);
    message.clearOptions();
    expect(message.optionMap.length, 0);
  });

  test('Acknowledged', () {
    var acked = false;
    void ackHook() {
      acked = true;
    }

    final message = CoapEmptyMessage(CoapMessageType.rst)
      ..isAcknowledged = true;
    expect(message.isAcknowledged, isTrue);
    expect(acked, isFalse);
    final eventBus = CoapEventBus(namespace: '');
    expect(eventBus.lastEvent is CoapAcknowledgedEvent, isTrue);
    eventBus.lastEvent = null;
    message
      ..acknowledgedHook = ackHook
      ..isAcknowledged = false;
    expect(message.isAcknowledged, isFalse);
    expect(acked, isTrue);
    expect(eventBus.lastEvent is CoapAcknowledgedEvent, isTrue);
  });

  test('Rejected', () {
    final message = CoapEmptyMessage(CoapMessageType.rst)..isRejected = true;
    expect(message.isRejected, isTrue);
    final eventBus = CoapEventBus(namespace: '');
    expect(eventBus.lastEvent is CoapRejectedEvent, isTrue);
  });

  test('Timed out', () {
    var timedOut = false;
    void toHook() {
      timedOut = true;
    }

    final message = CoapEmptyMessage(CoapMessageType.rst)..isTimedOut = true;
    expect(message.isTimedOut, isTrue);
    expect(timedOut, isFalse);
    final eventBus = CoapEventBus(namespace: '');
    expect(eventBus.lastEvent is CoapTimedOutEvent, isTrue);
    eventBus.lastEvent = null;
    message
      ..timedOutHook = toHook
      ..isTimedOut = false;
    expect(message.isTimedOut, isFalse);
    expect(timedOut, isTrue);
    expect(eventBus.lastEvent is CoapTimedOutEvent, isTrue);
  });

  test('Retransmitting', () {
    final message = CoapEmptyMessage(CoapMessageType.rst)..isTimedOut = true;
    var retrans = false;
    void retransHook() {
      retrans = true;
    }

    message.fireRetransmitting();
    expect(retrans, isFalse);
    message
      ..retransmittingHook = retransHook
      ..fireRetransmitting();
    expect(retrans, isTrue);
  });

  test('Payload', () {
    final message = CoapEmptyMessage(CoapMessageType.rst)
      ..isTimedOut = true
      ..setPayload('This is the payload');
    expect(message.payload, isNotNull);
    expect(message.payloadString, 'This is the payload');
    expect(message.payloadSize, 19);
  });

  test('If match', () {
    final message = CoapEmptyMessage(CoapMessageType.rst)..isTimedOut = true;
    expect(message.ifMatches.length, 0);
    message
      ..addIfMatch('ETag-1')
      ..addIfMatch('ETag-2');
    expect(message.ifMatches.length, 2);
    expect(message.ifMatches.toList()[0].stringValue, 'ETag-1');
    expect(message.ifMatches.toList()[1].stringValue, 'ETag-2');
    message.removeIfMatchOpaque(message.ifMatches.toList()[0].byteValue);
    expect(message.ifMatches.length, 1);
    expect(message.ifMatches.toList()[0].stringValue, 'ETag-2');
    message.clearIfMatches();
    expect(message.ifMatches.length, 0);
    final opt1 = CoapOption(OptionType.uriHost);
    expect(() => message.removeIfMatch(opt1), throwsArgumentError);
    final opt2 = CoapOption(OptionType.ifMatch)..stringValue = 'ETag-3';
    message.addOption(opt2);
    expect(message.ifMatches.length, 1);
    message.removeIfMatch(opt2);
    expect(message.ifMatches.length, 0);
  });

  test('ETags', () {
    final message = CoapEmptyMessage(CoapMessageType.rst)..isTimedOut = true;
    expect(message.etags.length, 0);
    final none = CoapOption(OptionType.ifMatch);
    final etag1 = CoapOption(OptionType.eTag)..stringValue = 'Etag-1';
    final etag2 = CoapOption(OptionType.eTag)..stringValue = 'Etag-2';
    expect(() => message.addEtag(none), throwsArgumentError);
    message.addEtag(etag1);
    expect(message.etags.length, 1);
    message.addETagOpaque(etag2.byteValue);
    expect(message.etags.length, 2);
    message.removeETagOpaque(etag2.byteValue);
    expect(message.etags.length, 1);
    expect(message.etags.toList()[0] == etag1, isTrue);
    message.clearETags();
    expect(message.etags.length, 0);
    message.addEtag(etag1);
    expect(message.etags.length, 1);
    expect(() => message.removeEtag(none), throwsArgumentError);
    final ret = message.removeEtag(etag1);
    expect(ret, isTrue);
    expect(message.etags.length, 0);
  });

  test('If None match', () {
    final message = CoapEmptyMessage(CoapMessageType.rst)..isTimedOut = true;
    expect(message.ifNoneMatches.length, 0);
    final none = CoapOption(OptionType.ifMatch);
    final inm1 = CoapOption(OptionType.ifNoneMatch)..stringValue = 'Inm1';
    final inm2 = CoapOption(OptionType.ifNoneMatch)..stringValue = 'Inm2';
    message
      ..addIfNoneMatch(inm1)
      ..addIfNoneMatch(inm2);
    expect(message.ifNoneMatches.length, 2);
    expect(() => message.addIfNoneMatch(none), throwsArgumentError);
    final inm3 = CoapOption(OptionType.ifNoneMatch)..stringValue = 'Inm3';
    message.addIfNoneMatchOpaque(inm3.byteValue);
    expect(message.ifNoneMatches.length, 3);
    message.removeIfNoneMatchOpaque(inm2.byteValue);
    expect(message.ifNoneMatches.length, 2);
    expect(() => message.removeIfNoneMatch(none), throwsArgumentError);
    message.clearIfNoneMatches();
    expect(message.ifNoneMatches.length, 0);
  });

  test('Uri path', () {
    final message = CoapEmptyMessage(CoapMessageType.rst)..isTimedOut = true;
    expect(message.uriPaths.length, 0);
    for (final path in ['/a/uri/path', 'a/uri/path/', '/a/uri/path/']) {
      message.uriPath = path;
      expect(message.uriPaths.length, 3);
      expect(message.uriPath, 'a/uri/path');
    }
    message.addUriPath('longer');
    expect(message.uriPaths.length, 4);
    expect(message.uriPath, 'a/uri/path/longer');
    expect(
      () => message.addUriPath('multiple/not/allowed'),
      throwsArgumentError,
    );
    expect(
      () => message.addLocationPath('no-double-slash//'),
      throwsArgumentError,
    );
    final tooLong = 'n' * 1000;
    expect(() => message.addUriPath(tooLong), throwsArgumentError);
    message.removeUriPath('path');
    expect(message.uriPaths.length, 3);
    expect(message.uriPath, 'a/uri/longer');
    message.clearUriPath();
    expect(message.uriPaths.length, 0);
    expect(message.uriPath.isEmpty, isTrue);
    message.uriPath = 'a//uri/path';
    expect(message.uriPaths.length, 4);
    expect(message.uriPath, 'a//uri/path');
    message
      ..clearUriPath()
      ..addUriPath('');
    expect(message.uriPaths.length, 1);
    expect(message.uriPath, '');
  });

  test('Uri query', () {
    final message = CoapEmptyMessage(CoapMessageType.rst);
    expect(message.uriQueries.length, 0);
    message.uriQuery = 'a&uri=1&query=2';
    expect(message.uriQueries.length, 3);
    expect(message.uriQuery, 'a&uri=1&query=2');
    message.addUriQuery('longer=3');
    expect(message.uriQueries.length, 4);
    expect(message.uriQuery, 'a&uri=1&query=2&longer=3');
    final tooLong = 'n' * 1000;
    expect(() => message.addUriQuery(tooLong), throwsArgumentError);
    expect(
      () => message.addUriQuery('no=1&multiple=2&queries=3'),
      throwsArgumentError,
    );
    expect(
      () => message.addLocationQuery('no_double_and=1&&'),
      throwsArgumentError,
    );
    message.removeUriQuery('query=2');
    expect(message.uriQueries.length, 3);
    expect(message.uriQuery, 'a&uri=1&longer=3');
    message.clearUriQuery();
    expect(message.uriQueries.length, 0);
  });

  test('Location path', () {
    final message = CoapEmptyMessage(CoapMessageType.rst);
    expect(message.locationPaths.length, 0);
    message.locationPath = 'a/location/path/';
    expect(message.locationPaths.length, 3);
    expect(message.locationPath, 'a/location/path');
    message.addLocationPath('longer');
    expect(message.locationPaths.length, 4);
    expect(message.locationPath, 'a/location/path/longer');
    message.removelocationPath('path');
    expect(message.locationPaths.length, 3);
    expect(message.locationPath, 'a/location/longer');
    message.clearLocationPath();
    expect(message.locationPaths.length, 0);
    expect(message.locationPath.isEmpty, isTrue);
    message.locationPath = 'a//uri/path';
    expect(message.locationPaths.length, 4);
    expect(message.locationPath, 'a//uri/path');
    message
      ..clearLocationPath()
      ..addLocationPath('');
    expect(message.locationPaths.length, 1);
    expect(message.locationPath, '');
    expect(() => message.locationPath = '..', throwsArgumentError);
    expect(() => message.locationPath = '.', throwsArgumentError);
    expect(
      () => message.addLocationPath('multiple/not/allowed'),
      throwsArgumentError,
    );
    expect(
      () => message.addLocationPath('no-double-slash//'),
      throwsArgumentError,
    );
    final tooLong = 'n' * 1000;
    expect(() => message.addLocationPath(tooLong), throwsArgumentError);
  });

  test('Location query', () {
    final message = CoapEmptyMessage(CoapMessageType.rst);
    expect(message.locationQueries.length, 0);
    message.locationQuery = 'a&uri=1&query=2';
    expect(message.locationQueries.length, 3);
    expect(message.locationQuery, 'a&uri=1&query=2');
    message.addLocationQuery('longer=3');
    expect(message.locationQueries.length, 4);
    expect(message.locationQuery, 'a&uri=1&query=2&longer=3');
    final tooLong = 'n' * 1000;
    expect(() => message.addLocationQuery(tooLong), throwsArgumentError);
    expect(
      () => message.addLocationQuery('no=1&multiple=2&queries=3'),
      throwsArgumentError,
    );
    expect(
      () => message.addLocationQuery('no_double_and=1&&'),
      throwsArgumentError,
    );
    message.removeLocationQuery('query=2');
    expect(message.locationQueries.length, 3);
    expect(message.locationQuery, 'a&uri=1&longer=3');
    message.clearLocationQuery();
    expect(message.locationQueries.length, 0);
  });
}
