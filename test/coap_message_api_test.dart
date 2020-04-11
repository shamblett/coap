/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 20/09/2019
 * Copyright :  S.Hamblett
 */

import 'package:coap/coap.dart';
import 'package:coap/config/coap_config_logging.dart';
import 'package:test/test.dart';

// Note that nnot all API methods are tested here, some are tested in other unit test suites,
// some in dynamic testing.
void main() {
  // ignore: unused_local_variable
  final DefaultCoapConfig conf = CoapConfigLogging();

  test('Construction', () {
    final message = CoapMessage();
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
    final message = CoapMessage();
    final opt1 = CoapOption(optionTypeUriHost);
    final opt2 = CoapOption(optionTypeReserved);
    final options = <CoapOption>[opt1, opt2];
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
    final opt3 = CoapOption(optionTypeUriHost);
    message.addOption(opt3);
    expect(message.optionMap.length, 2);
    expect(message.getOptions(optionTypeUriHost).length, 2);
    final ret = message.removeOption(opt1);
    expect(ret, isTrue);
    expect(message.getOptions(optionTypeUriHost).length, 1);
    expect(message.getOptions(optionTypeUriHost).toList()[0] == opt3, isTrue);
    message.clearOptions();
    expect(message.optionMap.length, 0);
  });

  test('Message codes', () {
    final message = CoapMessage();
    expect(message.isRequest, isFalse);
    expect(message.isResponse, isFalse);
    expect(message.isEmpty, isFalse);
    expect(message.isValid, isFalse);
    expect(message.codeString, 'Not Set');
  });

  test('Acknowledged', () {
    var acked = false;
    void ackHook() {
      acked = true;
    }

    final message = CoapMessage();
    message.isAcknowledged = true;
    expect(message.isAcknowledged, isTrue);
    expect(acked, isFalse);
    final eventBus = CoapEventBus();
    expect(eventBus.lastEvent is CoapAcknowledgedEvent, isTrue);
    eventBus.lastEvent = null;
    message.acknowledgedHook = ackHook;
    message.isAcknowledged = false;
    expect(message.isAcknowledged, isFalse);
    expect(acked, isTrue);
    expect(eventBus.lastEvent, isNull);
  });

  test('Rejected', () {
    final message = CoapMessage();
    message.isRejected = true;
    expect(message.isRejected, isTrue);
    final eventBus = CoapEventBus();
    expect(eventBus.lastEvent is CoapRejectedEvent, isTrue);
  });

  test('Timed out', () {
    var timedOut = false;
    void toHook() {
      timedOut = true;
    }

    final message = CoapMessage();
    message.isTimedOut = true;
    expect(message.isTimedOut, isTrue);
    expect(timedOut, isFalse);
    final eventBus = CoapEventBus();
    expect(eventBus.lastEvent is CoapTimedOutEvent, isTrue);
    eventBus.lastEvent = null;
    message.timedOutHook = toHook;
    message.isTimedOut = false;
    expect(message.isTimedOut, isFalse);
    expect(timedOut, isTrue);
    expect(eventBus.lastEvent, isNull);
  });

  test('Retransmitting', () {
    final message = CoapMessage();
    var retrans = false;
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
    final message = CoapMessage();
    message.isCancelled = true;
    expect(message.isCancelled, isTrue);
    final eventBus = CoapEventBus();
    expect(eventBus.lastEvent is CoapCancelledEvent, isTrue);
    message.isCancelled = false;
    message.cancel();
    expect(message.isCancelled, isTrue);
  });

  test('Payload', () {
    final message = CoapMessage();
    message.setPayload('This is the payload');
    expect(message.payload, isNotNull);
    expect(message.payloadString, 'This is the payload');
    expect(message.payloadSize, 19);
  });

  test('If match', () {
    final message = CoapMessage();
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
    final opt1 = CoapOption(optionTypeUriHost);
    expect(() => message.removeIfMatch(opt1), throwsArgumentError);
    final opt2 = CoapOption(optionTypeIfMatch);
    opt2.stringValue = 'ETag-3';
    message.addOption(opt2);
    expect(message.ifMatches.length, 1);
    message.removeIfMatch(opt2);
    expect(message.ifMatches.length, 0);
  });

  test('ETags', () {
    final message = CoapMessage();
    expect(message.etags.length, 0);
    final none = CoapOption(optionTypeIfMatch);
    final etag1 = CoapOption(optionTypeETag);
    etag1.stringValue = 'Etag-1';
    final etag2 = CoapOption(optionTypeETag);
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
    final ret = message.removeEtag(etag1);
    expect(ret, isTrue);
    expect(message.etags.length, 0);
  });

  test('If None match', () {
    final message = CoapMessage();
    expect(message.ifNoneMatches.length, 0);
    final none = CoapOption(optionTypeIfMatch);
    final inm1 = CoapOption(optionTypeIfNoneMatch);
    inm1.stringValue = 'Inm1';
    final inm2 = CoapOption(optionTypeIfNoneMatch);
    inm2.stringValue = 'Inm2';
    message.addIfNoneMatch(inm1).addIfNoneMatch(inm2);
    expect(message.ifNoneMatches.length, 2);
    expect(() => message.addIfNoneMatch(none), throwsArgumentError);
    final inm3 = CoapOption(optionTypeIfNoneMatch);
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
    final message = CoapMessage();
    expect(message.uriPaths.length, 0);
    message.uriPath = 'a/uri/path/';
    expect(message.uriPaths.length, 3);
    expect(message.uriPathsString, 'a/uri/path');
    message.addUriPath('longer');
    expect(message.uriPaths.length, 4);
    expect(message.uriPathsString, 'a/uri/path/longer');
    expect(() => message.addUriPath(null), throwsArgumentError);
    const tolong =
        'nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn'
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
        'nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn';
    expect(() => message.addUriPath(tolong), throwsArgumentError);
    message.removeUriPath('path');
    expect(message.uriPaths.length, 3);
    expect(message.uriPathsString, 'a/uri/longer');
    message.clearUriPath();
    expect(message.uriPaths.length, 0);
    expect(message.uriPathsString.isEmpty, isTrue);
  });

  test('Uri query', () {
    final message = CoapMessage();
    expect(message.uriQueries.length, 0);
    message.uriQuery = 'a&uri=1&query=2';
    expect(message.uriQueries.length, 3);
    expect(message.uriQueriesString, '?a&uri=1&query=2');
    message.addUriQuery('longer=3');
    expect(message.uriQueries.length, 4);
    expect(message.uriQueriesString, '?a&uri=1&query=2&longer=3');
    expect(() => message.addUriQuery(null), throwsArgumentError);
    const tolong =
        'nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn'
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
        'nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn';
    expect(() => message.addUriQuery(tolong), throwsArgumentError);
    message.removeUriQuery('query=2');
    expect(message.uriQueries.length, 3);
    expect(message.uriQueriesString, '?a&uri=1&longer=3');
    message.clearUriQuery();
    expect(message.uriQueries.length, 0);
  });

  test('Location path', () {
    final message = CoapMessage();
    expect(message.locationPaths.length, 0);
    message.locationPath = 'a/location/path/';
    expect(message.locationPaths.length, 3);
    expect(message.locationPathsString, 'a/location/path');
    expect(() => message.locationPath = '..', throwsArgumentError);
    expect(() => message.locationPath = '.', throwsArgumentError);
    message.addLocationPath('longer');
    expect(message.locationPaths.length, 4);
    expect(message.locationPathsString, 'a/location/path/longer');
    expect(() => message.addLocationPath(null), throwsArgumentError);
    const tolong =
        'nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn'
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
        'nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn';
    expect(() => message.addLocationPath(tolong), throwsArgumentError);
    message.removelocationPath('path');
    expect(message.locationPaths.length, 3);
    expect(message.locationPathsString, 'a/location/longer');
    message.clearLocationPath();
    expect(message.locationPaths.length, 0);
    expect(message.locationPathsString.isEmpty, isTrue);
  });

  test('Location query', () {
    final message = CoapMessage();
    expect(message.locationQueries.length, 0);
    message.locationQuery = 'a&uri=1&query=2';
    expect(message.locationQueries.length, 3);
    expect(message.locationQueriesString, '?a&uri=1&query=2');
    message.addLocationQuery('longer=3');
    expect(message.locationQueries.length, 4);
    expect(message.locationQueriesString, '?a&uri=1&query=2&longer=3');
    expect(() => message.addLocationQuery(null), throwsArgumentError);
    const tolong =
        'nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn'
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
        'nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn';
    expect(() => message.addLocationQuery(tolong), throwsArgumentError);
    message.removeLocationQuery('query=2');
    expect(message.locationQueries.length, 3);
    expect(message.locationQueriesString, '?a&uri=1&longer=3');
    message.clearLocationQuery();
    expect(message.locationQueries.length, 0);
  });
}
