/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 20/09/2019
 * Copyright :  S.Hamblett
 */

import 'dart:convert';
import 'dart:io';

import 'package:coap/coap.dart';
import 'package:coap/src/coap_empty_message.dart';
import 'package:coap/src/event/coap_event_bus.dart';
import 'package:coap/src/option/coap_option_type.dart';
import 'package:convert/convert.dart';
import 'package:test/test.dart';
import 'package:typed_data/typed_buffers.dart';

// Note that not all API methods are tested here, some are tested in other unit
// test suites, some in dynamic testing.
void main() {
  // ignore: unused_local_variable
  final DefaultCoapConfig conf = CoapConfigDefault();

  test('Construction', () {
    final message = CoapEmptyMessage(CoapMessageType.con);
    expect(message.type, CoapMessageType.con);
    expect(message.id, null);
    expect(message.optionsLength == 0, isTrue);
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
    expect(message.payload, isEmpty);
    expect(message.payloadSize, 0);
    expect(message.payloadString, '');
  });

  test('Options', () {
    final emptyUri = Uri();
    final message = CoapRequest(RequestMethod.get, emptyUri);
    final opt1 = UriQueryOption.parse(Uint8Buffer());
    expect(
      () => OptionType.fromTypeNumber(9000),
      throwsA(const TypeMatcher<UnknownElectiveOptionException>()),
    );
    expect(
      () => OptionType.fromTypeNumber(9001),
      throwsA(const TypeMatcher<UnknownCriticalOptionException>()),
    );
    final options = [opt1];
    message.addOptions(options);
    expect(message.optionsLength, 1);
    expect(message.getOptions<UriQueryOption>().length, 1);
    message.setOption(opt1);
    expect(message.optionsLength, 1);
    expect(message.getOptions<UriQueryOption>().length, 1);
    message.setOptions(options);
    expect(message.optionsLength, 1);
    expect(message.getOptions<UriQueryOption>().length, 1);
    expect(
      message.getFirstOption<UriQueryOption>()!.type,
      OptionType.uriQuery,
    );
    expect(message.getFirstOption<UriPortOption>(), isNull);
    expect(message.hasOption<UriQueryOption>(), isTrue);
    expect(message.hasOption<UriPortOption>(), isFalse);
    message.removeOptions<UriQueryOption>();
    expect(message.optionsLength, 0);
    expect(message.getOptions<UriQueryOption>(), <Option<Object?>>[]);
    expect(message.optionsLength, 0);
    expect(message.getOptions<UriQueryOption>(), <Option<Object?>>[]);
    message.addOptions(options);
    expect(message.optionsLength, 1);
    final opt2 = UriQueryOption.parse(Uint8Buffer());
    message.addOption(opt2);
    expect(message.optionsLength, 2);
    expect(message.getOptions<UriQueryOption>().length, 2);
    final ret = message.removeOption(opt1);
    expect(ret, isTrue);
    expect(message.getOptions<UriQueryOption>().length, 1);
    expect(
      message.getOptions<UriQueryOption>().toList()[0] == opt2,
      isTrue,
    );
    message.clearOptions();
    expect(message.optionsLength, 0);
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
    expect(utf8.decode(message.ifMatches.toList()[0].byteValue), 'ETag-1');
    expect(utf8.decode(message.ifMatches.toList()[1].byteValue), 'ETag-2');
    message.removeIfMatchOpaque(message.ifMatches.toList()[0].byteValue);
    expect(message.ifMatches.length, 1);
    expect(utf8.decode(message.ifMatches.toList()[0].byteValue), 'ETag-2');
    message.clearIfMatches();
    expect(message.ifMatches.length, 0);
    final opt1 = IfMatchOption(Uint8Buffer()..addAll('ETag-3'.codeUnits));
    message.addOption(opt1);
    expect(message.ifMatches.length, 1);
    message.removeIfMatch(opt1);
    expect(message.ifMatches.length, 0);
  });

  test('ETags', () {
    final message = CoapEmptyMessage(CoapMessageType.rst)..isTimedOut = true;
    expect(message.etags.length, 0);
    final etag1 = ETagOption(Uint8Buffer()..addAll('ETag-1'.codeUnits));
    final etag2 = ETagOption(Uint8Buffer()..addAll('ETag-2'.codeUnits));
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
    final ret = message.removeEtag(etag1);
    expect(ret, isTrue);
    expect(message.etags.length, 0);
  });

  test('If None match', () {
    final message = CoapEmptyMessage(CoapMessageType.rst)..isTimedOut = true;
    expect(message.ifNoneMatches.length, 0);
    final inm1 = IfNoneMatchOption();
    final inm2 = IfNoneMatchOption();
    expect(inm1 == inm2, isTrue);

    message
      ..addOption(inm1)
      ..addOption(inm2);
    expect(message.ifNoneMatches.length, 1);
    message.removeIfNoneMatch(inm1);
    expect(message.ifNoneMatches.length, 0);
  });

  test('Uri path', () {
    final emptyUri = Uri();
    final message = CoapRequest(RequestMethod.get, emptyUri)..isTimedOut = true;
    expect(message.uriPaths.length, 0);
    for (final path in ['', '/']) {
      message.uriPath = path;
      expect(message.uriPaths.length, 0);
    }
    for (final path in ['a/uri/path/', '/a/uri/path/']) {
      message.uriPath = path;
      expect(message.uriPaths.length, 4);
      expect(message.uriPath, '/a/uri/path/');
    }
    message.addUriPath('longer');
    expect(message.uriPaths.length, 5);
    expect(message.uriPath, '/a/uri/path//longer');
    message.addUriPath('multiple/are/allowed');
    expect(message.uriPath, '/a/uri/path//longer/multiple%2Fare%2Fallowed');
    message.addUriPath('no-double-slash//');
    expect(
      message.uriPath,
      '/a/uri/path//longer/multiple%2Fare%2Fallowed/no-double-slash%2F%2F',
    );
    final tooLong = 'n' * 1000;
    expect(
      () => message.addUriPath(tooLong),
      throwsA(isA<UnknownCriticalOptionException>()),
    );
    message.removeUriPath('path');
    expect(message.uriPaths.length, 6);
    expect(
      message.uriPath,
      '/a/uri//longer/multiple%2Fare%2Fallowed/no-double-slash%2F%2F',
    );
    message.clearUriPath();
    expect(message.uriPaths.length, 0);
    expect(message.uriPath.isEmpty, isFalse);
    message.uriPath = '/a//uri/path';
    expect(message.uriPaths.length, 4);
    expect(message.uriPath, '/a//uri/path');
    message
      ..clearUriPath()
      ..addUriPath('');
    expect(message.uriPaths.length, 1);
    expect(message.uriPath, '/');

    message.uriPath = 'ä/ö/ü';
    expect(message.uriPaths.length, 3);
    expect(message.uriPath, '/%C3%A4/%C3%B6/%C3%BC');
  });

  test('Uri query', () {
    final emptyUri = Uri();
    final message = CoapRequest(RequestMethod.get, emptyUri);
    expect(message.uriQueries.length, 0);
    message.uriQuery = 'a&uri=1&query=2';
    expect(message.uriQueries.length, 3);
    expect(message.uriQuery, 'a&uri=1&query=2');
    message.addUriQuery('longer=3');
    expect(message.uriQueries.length, 4);
    expect(message.uriQuery, 'a&uri=1&query=2&longer=3');
    final tooLong = 'n' * 1000;
    expect(
      () => message.addUriQuery(tooLong),
      throwsA(isA<UnknownCriticalOptionException>()),
    );
    message.addUriQuery('allow=1&multiple=2&queries=3');
    expect(
      message.uriQuery,
      'a&uri=1&query=2&longer=3&allow=1%26multiple%3D2%26queries%3D3',
    );
    message.addUriPath('no_double_and=1&&');
    expect(
      message.uriQuery,
      'a&uri=1&query=2&longer=3&allow=1%26multiple%3D2%26queries%3D3',
    );
    message.removeUriQuery('query=2');
    expect(message.uriQueries.length, 4);
    expect(
      message.uriQuery,
      'a&uri=1&longer=3&allow=1%26multiple%3D2%26queries%3D3',
    );
    message.clearUriQuery();
    expect(message.uriQueries.length, 0);

    message.uriQuery = 'äöü';
    expect(message.uriQueries.length, 1);
    expect(message.uriQuery, '%C3%A4%C3%B6%C3%BC');
  });

  test('Location path', () {
    final message = CoapResponse(ResponseCode.content, CoapMessageType.ack);
    expect(message.locationPaths.length, 0);
    message.locationPath = '';
    expect(message.locationPaths.length, 1);
    expect(message.locationPath, '/');
    message.locationPath = '/';
    expect(message.locationPaths.length, 1);
    expect(message.locationPath, '/');
    message.locationPath = 'a/location/path/';
    expect(message.locationPaths.length, 4);
    expect(message.locationPath, '/a/location/path/');
    message.addLocationPath('longer');
    expect(message.locationPaths.length, 5);
    expect(message.locationPath, '/a/location/path//longer');
    message.removelocationPath('path');
    expect(message.locationPaths.length, 4);
    expect(message.locationPath, '/a/location//longer');
    message.clearLocationPath();
    expect(message.locationPaths.length, 0);
    expect(message.locationPath.isEmpty, isFalse);
    message.locationPath = 'a//uri/path';
    expect(message.locationPaths.length, 4);
    expect(message.locationPath, '/a//uri/path');
    message
      ..clearLocationPath()
      ..addLocationPath('');
    expect(message.locationPaths.length, 1);
    expect(message.locationPath, '/');
    expect(() => message.locationPath = '..', throwsFormatException);
    expect(() => message.locationPath = '.', throwsFormatException);
    message.addLocationPath('multiple/are/allowed');
    expect(message.locationPaths.length, 1);
    message.addLocationPath('double-slash//');
    expect(message.locationPaths.length, 2);
    final tooLong = 'n' * 1000;
    expect(
      () => message.addLocationPath(tooLong),
      throwsA(isA<UnknownElectiveOptionException>()),
    );

    message.locationPath = 'ä/ö/ü';
    expect(message.locationPaths.length, 3);
    expect(message.locationPath, '/%C3%A4/%C3%B6/%C3%BC');
  });

  test('Location query', () {
    final message = CoapResponse(ResponseCode.content, CoapMessageType.ack);
    expect(message.locationQueries.length, 0);
    message.locationQuery = 'a&uri=1&query=2';
    expect(message.locationQueries.length, 3);
    expect(message.locationQuery, 'a&uri=1&query=2');
    message.addLocationQuery('longer=3');
    expect(message.locationQueries.length, 4);
    expect(message.locationQuery, 'a&uri=1&query=2&longer=3');
    final tooLong = 'n' * 1000;
    expect(
      () => message.addLocationQuery(tooLong),
      throwsA(isA<UnknownElectiveOptionException>()),
    );
    message.addLocationQuery('allow=1&multiple=2&queries=3');
    expect(
      message.locationQuery,
      'a&uri=1&query=2&longer=3&allow=1%26multiple%3D2%26queries%3D3',
    );
    message.addLocationQuery('double_and=1&&');
    expect(
      message.locationQuery,
      'a&uri=1&query=2&longer=3&allow=1%26multiple%3D2%26queries%3D3'
      '&double_and=1%26%26',
    );
    message.removeLocationQuery('query=2');
    expect(message.locationQueries.length, 5);
    expect(
      message.locationQuery,
      'a&uri=1&longer=3&allow=1%26multiple%3D2%26queries%3D3'
      '&double_and=1%26%26',
    );
    message.clearLocationQuery();
    expect(message.locationQueries.length, 0);

    message.locationQuery = 'ä&ö/ü';
    expect(message.locationQueries.length, 2);
    expect(message.locationQuery, '%C3%A4&%C3%B6%2F%C3%BC');
  });

  /// Runs examples from [RFC 7252, Appendix B].
  ///
  /// [RFC 7252, Appendix B]: https://www.rfc-editor.org/rfc/rfc7252#appendix-B
  test('Multiple URI options', () {
    final emptyUri = Uri();
    final message1 = CoapRequest(RequestMethod.get, emptyUri)
      ..uriHost = '[2001:db8::2:1]'
      ..uriPort = 5683;

    expect(message1.uri.toString(), 'coap://[2001:db8::2:1]/');

    final message2 = CoapRequest(RequestMethod.get, emptyUri)
      ..uriHost = 'example.net'
      ..uriPort = 5683;

    expect(message2.uri.toString(), 'coap://example.net/');

    final message3 = CoapRequest(RequestMethod.get, emptyUri)
      ..uriHost = 'example.net'
      ..uriPort = 5683
      ..addUriPath('.well-known')
      ..addUriPath('core');

    expect(message3.uri.toString(), 'coap://example.net/.well-known/core');

    final message4 = CoapRequest(RequestMethod.get, emptyUri)
      ..uriHost = 'xn--18j4d.example'
      ..uriPort = 5683
      ..addUriPath(utf8.decode(hex.decode('E38193E38293E381ABE381A1E381AF')));

    expect(
      message4.uri.toString(),
      'coap://xn--18j4d.example/%E3%81%93%E3%82%93%E3%81%AB%E3%81%A1%E3%81%AF',
    );

    final message5 = CoapRequest(RequestMethod.get, emptyUri)
      ..destination = InternetAddress('198.51.100.1')
      ..uriPort = 61616
      ..addUriPath('')
      ..addUriPath('/')
      ..addUriPath('')
      ..addUriPath('')
      ..addUriQuery('//')
      ..addUriQuery('?&');

    expect(
      message5.uri.toString(),
      // FIXME: Should be "coap://198.51.100.1:61616//%2F//?%2F%2F&?%26"
      'coap://198.51.100.1:61616//%2F//?%2F%2F&%3F%26',
    );
  });
}
