/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/05/2017
 * Copyright :  S.Hamblett
 */

//
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:typed_data/typed_data.dart';

import 'coap_code.dart';
import 'coap_constants.dart';
import 'coap_media_type.dart';
import 'coap_message_type.dart';
import 'coap_response.dart';
import 'codec/udp/message_decoder.dart';
import 'codec/udp/message_encoder.dart';
import 'event/coap_event_bus.dart';
import 'option/coap_block_option.dart';
import 'option/coap_option_type.dart';
import 'option/empty_option.dart';
import 'option/integer_option.dart';
import 'option/opaque_option.dart';
import 'option/option.dart';
import 'option/string_option.dart';
import 'util/coap_byte_array_util.dart';

typedef HookFunction = void Function();

/// The class Message models the base class of all CoAP messages.
/// CoAP messages are of type Request, Response or EmptyMessage,
/// each of which has a MessageType, a message identifier,
/// a token (0-8 bytes), a collection of Options and a payload.
abstract class CoapMessage {
  CoapMessage(this.code, this._type);

  CoapMessage.fromParsed(
    this.code,
    this._type, {
    required final int id,
    required final Uint8Buffer token,
    required final List<Option<Object?>> options,
    required this.hasUnknownCriticalOption,
    required this.hasFormatError,
    this.payload,
  }) {
    this.id = id;
    this.token = token;
    setOptions(options);
  }

  bool hasUnknownCriticalOption = false;

  bool hasFormatError = false;

  CoapMessageType? _type;

  @internal
  set type(final CoapMessageType? type) => _type = type;

  /// The type of this CoAP message.
  CoapMessageType? get type => _type;

  /// The code of this CoAP message.
  final CoapCode code;

  /// The codestring
  String get codeString => code.toString();

  int? _id;

  /// The ID of this CoAP message.
  int? get id => _id;
  @internal
  set id(final int? val) => _id = val;

  final List<Option<Object?>> _options = [];

  int get optionsLength => _options.length;

  CoapEventBus? _eventBus = CoapEventBus(namespace: '');

  /// Bind address if not using the default
  InternetAddress? bindAddress;

  @internal
  set eventBus(final CoapEventBus? eventBus) => _eventBus = eventBus;

  CoapEventBus? get eventBus => _eventBus;

  String? get namespace => _eventBus?.namespace;

  /// Adds an option to the list of options of this [CoapMessage].
  void addOption(final Option<Object?> option) {
    if (!option.repeatable) {
      _options.removeWhere((final element) => element.type == option.type);
    }
    _options.add(option);
  }

  bool get needsRejection =>
      // TODO(JKRhb): Revisit conditions for rejection
      (type == CoapMessageType.non && hasUnknownCriticalOption) ||
      hasFormatError ||
      (this is CoapResponse && hasUnknownCriticalOption);

  /// Remove a specific option, returns true if the option has been removed.
  bool removeOption(final Option<Object?> option) => _options.remove(option);

  /// Adds options to the list of options of this CoAP message.
  void addOptions(final Iterable<Option<Object?>> options) =>
      options.forEach(addOption);

  /// Removes all options of the given type from this CoAP message.
  void removeOptions<T extends Option<Object?>>() =>
      _options.removeWhere((final element) => element is T);

  /// Gets all options of the given type.
  List<T> getOptions<T extends Option<Object?>>() =>
      _options.whereType<T>().toList();

  /// Gets a list of all options.
  List<Option<Object?>> getAllOptions() => _options.toList();

  /// Sets an option, removing all others of the option type
  void setOption<T extends Option<Object?>>(final T option) {
    removeOptions<T>();
    addOption(option);
  }

  /// Sets all options with the specified option type, removing
  /// all others of the same type.
  void setOptions(final Iterable<Option<Object?>> options) {
    for (final option in options) {
      _options.removeWhere((final element) => element.type == option.type);
    }
    addOptions(options);
  }

  /// Returns the first option of the specified type, or null
  T? getFirstOption<T extends Option<Object?>>() => getOptions<T>().firstOrNull;

  /// Clear all options
  void clearOptions() => _options.clear();

  /// Checks if this CoAP message has options of the specified option type.
  /// Returns true if options of the specified type exists.
  bool hasOption<T extends Option<Object?>>() => getFirstOption<T>() != null;

  Uint8Buffer? _token;

  /// The 0-8 byte token.
  Uint8Buffer? get token => _token;

  /// As a string
  String get tokenString {
    final token = _token;
    return token != null ? CoapByteArrayUtil.toHexString(token) : '';
  }

  set token(final Uint8Buffer? value) {
    const maxValue = (1 << 16) - 270;
    if (value != null && value.length > maxValue) {
      throw ArgumentError.value(
        value,
        'Message::token',
        'Token length must be between 0 and $maxValue inclusive.',
      );
    }
    _token = value;
  }

  /// Gets a value that indicates whether this CoAP message is a
  /// request message.
  bool get isRequest => code.isRequest;

  /// Gets a value that indicates whether this CoAP message is a
  /// response message.
  bool get isResponse => code.isResponse;

  /// Gets a value that indicates whether this CoAP message is
  /// an empty message.
  bool get isEmpty => code.isEmpty;

  /// The destination endpoint.
  @internal
  InternetAddress? destination;

  /// The source endpoint.
  @internal
  InternetAddress? source;

  /// Acknowledged hook for attaching a callback if needed
  HookFunction? acknowledgedHook;

  bool _acknowledged = false;

  /// Indicates whether this message has been acknowledged.
  bool get isAcknowledged => _acknowledged;
  @internal
  set isAcknowledged(final bool value) {
    _acknowledged = value;
    _eventBus?.fire(CoapAcknowledgedEvent(this));
    acknowledgedHook?.call();
  }

  bool _rejected = false;

  /// Indicates whether this message has been rejected.
  bool get isRejected => _rejected;
  @internal
  set isRejected(final bool value) {
    _rejected = value;
    _eventBus?.fire(CoapRejectedEvent(this));
  }

  /// Timed out hook function for attaching a callback if needed
  HookFunction? timedOutHook;

  bool _timedOut = false;

  /// Indicates whether this message has been timed out.
  bool get isTimedOut => _timedOut;
  @internal
  set isTimedOut(final bool value) {
    _timedOut = value;
    _eventBus?.fire(CoapTimedOutEvent(this));
    timedOutHook?.call();
  }

  /// Returns `true` if this [CoapMessage] has neither timed out nor has been
  /// canceled.
  // TODO(JKRhb): Should rejections be included here as well?
  bool get isActive => !isTimedOut && !isCancelled;

  /// Retransmit hook function
  HookFunction? retransmittingHook;

  int _retransmits = 0;

  /// The current number of retransmits
  int get retransmits => _retransmits;

  /// Fire retransmitting event
  void fireRetransmitting() {
    _retransmits++;
    _eventBus?.fire(CoapRetransmitEvent(this));
    retransmittingHook?.call();
  }

  bool _cancelled = false;

  /// Indicates whether this message has been cancelled.
  bool get isCancelled => _cancelled;
  @internal
  set isCancelled(final bool value) {
    _cancelled = value;
    _eventBus?.fire(CoapCancelledEvent(this));
  }

  bool _duplicate = false;

  /// Indicates whether this message is a duplicate.
  bool get duplicate => _duplicate;
  @internal
  set duplicate(final bool val) => _duplicate = val;

  DateTime? _timestamp;

  /// The timestamp when this message has been received or sent,
  /// or null if neither has happened yet.
  DateTime? get timestamp => _timestamp;
  @internal
  set timestamp(final DateTime? val) => _timestamp = val;

  /// The max times this message should be retransmitted if no ACK received.
  /// A value of 0 means that the CoapConstants.maxRetransmit time
  /// shoud be taken into account, while a negative means NO retransmission.
  /// The default value is 0.
  int maxRetransmit = 0;

  /// The amount of time in milliseconds after which this message will time out.
  /// A value of 0 indicates that the time should be decided
  /// automatically from the configuration.
  /// The default value is 0.
  int ackTimeout = 0;

  /// UTF8 decoder and encoder helpers
  final Utf8Decoder _utfDecoder = const Utf8Decoder();
  final Utf8Encoder _utfEncoder = const Utf8Encoder();

  /// The payload of this CoAP message.
  Uint8Buffer? payload;

  /// The size of the payload of this CoAP message.
  int get payloadSize => payload?.length ?? 0;

  /// The payload of this CoAP message in string representation.
  String get payloadString {
    final payload = this.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        final ret = _utfDecoder.convert(payload);
        return ret;
      } on FormatException catch (_) {
        // The payload may be incomplete, if so and the conversion
        // fails indicate this.
        return '<<<< Payload incomplete >>>>>';
      }
    }
    return '';
  }

  /// Sets the payload from a string with a default media type
  set payloadString(final String value) =>
      setPayloadMedia(value, CoapMediaType.textPlain);

  /// Sets the payload.
  void setPayload(final String payload) {
    this.payload ??= Uint8Buffer();
    this.payload!.addAll(_utfEncoder.convert(payload));
  }

  /// Sets the payload and media type of this CoAP message.
  void setPayloadMedia(final String payload, [final CoapMediaType? mediaType]) {
    final payloadBuffer = Uint8Buffer()..addAll(_utfEncoder.convert(payload));
    this.payload = payloadBuffer;
    contentType = mediaType;
  }

  /// Sets the payload of this CoAP message.
  void setPayloadMediaRaw(
    final Uint8Buffer payload, [
    final CoapMediaType? mediaType,
  ]) {
    this.payload = payload;
    contentType = mediaType;
  }

  /// Select options helper
  List<T> _selectOptions<T extends Option<Object?>>() => getOptions<T>();

  /// If-Matches.
  List<IfMatchOption> get ifMatches => _selectOptions<IfMatchOption>();

  /// Add an if match option
  void addIfMatch(final String etag) =>
      addOption(IfMatchOption(Uint8Buffer()..addAll(etag.codeUnits)));

  /// Add an opaque if match
  void addIfMatchOpaque(final Uint8Buffer opaque) {
    addOption(IfMatchOption(opaque));
  }

  /// Remove an opaque if match
  void removeIfMatchOpaque(final Uint8Buffer opaque) {
    _options.removeWhere(
      (final element) =>
          element.type == OptionType.ifMatch &&
          element.byteValue.equals(opaque),
    );
  }

  /// Remove an if match option
  void removeIfMatch(final IfMatchOption option) => removeOption(option);

  /// Clear the if matches
  void clearIfMatches() {
    removeOptions<IfMatchOption>();
  }

  /// Etags
  List<ETagOption> get etags => _selectOptions<ETagOption>();

  /// Contains an opaque E-tag
  bool containsETagOpaque(final Uint8Buffer opaque) =>
      getOptions<ETagOption>()
          .where((final element) => element.value.equals(opaque))
          .firstOrNull !=
      null;

  /// Add an opaque ETag
  void addETagOpaque(final Uint8Buffer opaque) {
    addOption(ETagOption(opaque));
  }

  /// Adds an ETag option
  void addEtag(final ETagOption option) => addOption(option);

  /// Remove an ETag, true indicates success
  bool removeEtag(final ETagOption option) => removeOption(option);

  /// Remove an opaque ETag
  void removeETagOpaque(final Uint8Buffer opaque) {
    _options.removeWhere(
      (final element) =>
          element.type == OptionType.eTag && element.byteValue.equals(opaque),
    );
  }

  /// Clear the E tags
  void clearETags() => removeOptions<ETagOption>();

  /// If-None Matches.
  List<IfNoneMatchOption> get ifNoneMatches =>
      _selectOptions<IfNoneMatchOption>();

  /// Remove an if none match option
  void removeIfNoneMatch(final IfNoneMatchOption option) {
    removeOption(option);
  }

  /// Uri's
  String get uriHost {
    final host = getFirstOption<UriHostOption>();
    return host?.toString() ?? '';
  }

  @internal
  set uriHost(final String value) {
    setOption(UriHostOption(value));
  }

  /// URI path
  // TODO(JKRhb): Apply proper percent-encoding
  String get uriPath => getOptions<UriPathOption>()
      .map((final e) => e.value.replaceAll('/', '%2F'))
      .join('/');

  /// Sets a number of Uri path options from a string
  set uriPath(final String fullPath) {
    clearUriPath();

    var trimmedPath = fullPath;

    if (fullPath.startsWith('/')) {
      trimmedPath = fullPath.substring(1);
    }

    if (trimmedPath.isEmpty) {
      return;
    }

    trimmedPath.split('/').forEach(addUriPath);
  }

  /// URI paths
  List<UriPathOption> get uriPaths => _selectOptions<UriPathOption>();

  /// Add a URI path
  void addUriPath(final String path) => addOption(UriPathOption(path));

  /// Remove a URI path
  void removeUriPath(final String path) {
    _options.removeWhere(
      (final element) => element is UriPathOption && element.value == path,
    );
  }

  /// Clear URI paths
  void clearUriPath() => removeOptions<UriPathOption>();

  /// URI query
  // TODO(JKRhb): Apply proper percent-encoding
  String get uriQuery => getOptions<UriQueryOption>()
      .map((final option) => option.value.replaceAll('&', '%26'))
      .join('&');

  /// Set a URI query
  set uriQuery(final String fullQuery) {
    var trimmedQuery = fullQuery;
    if (trimmedQuery.startsWith('?')) {
      trimmedQuery = trimmedQuery.substring(1);
    }
    clearUriQuery();
    trimmedQuery.split('&').forEach(addUriQuery);
  }

  /// URI queries
  List<UriQueryOption> get uriQueries => _selectOptions<UriQueryOption>();

  /// Add a URI query
  void addUriQuery(final String query) => addOption(UriQueryOption(query));

  /// Remove a URI query
  void removeUriQuery(final String query) {
    _options.removeWhere(
      (final element) => element is UriQueryOption && element.value == query,
    );
  }

  /// Clear URI queries
  void clearUriQuery() => removeOptions<UriQueryOption>();

  /// Uri port
  int get uriPort => getFirstOption<UriPortOption>()?.value ?? 0;

  set uriPort(final int value) {
    if (value == 0) {
      removeOptions<UriPortOption>();
    } else {
      addOption(UriPortOption(value));
    }
  }

  /// Location path as a string
  // TODO(JKRhb): Apply proper percent-encoding
  String get locationPath => getOptions<LocationPathOption>()
      .map((final option) => option.value.replaceAll('/', '%2F'))
      .join('/');

  /// Set the location path from a string
  set locationPath(final String fullPath) {
    clearLocationPath();

    var trimmedPath = fullPath;

    if (fullPath.startsWith('/')) {
      trimmedPath = fullPath.substring(1);
    }

    trimmedPath.split('/').forEach(addLocationPath);
  }

  /// Location paths
  List<LocationPathOption> get locationPaths =>
      _selectOptions<LocationPathOption>();

  /// Location
  String get location {
    var path = '/$locationPath';
    final query = locationQuery;
    if (query.isNotEmpty) {
      path += '?$query';
    }
    return path;
  }

  /// Add a location path
  void addLocationPath(final String path) =>
      addOption(LocationPathOption(path));

  /// Remove a location path
  void removelocationPath(final String path) {
    _options.removeWhere(
      (final element) => element is LocationPathOption && element.value == path,
    );
  }

  /// Clear location path
  void clearLocationPath() =>
      _options.removeWhere((final option) => option is LocationPathOption);

  /// Location query
  // TODO(JKRhb): Apply proper percent-encoding
  String get locationQuery => getOptions<LocationQueryOption>()
      .map((final e) => e.value.replaceAll('&', '%26'))
      .join('&');

  /// Set a location query
  set locationQuery(final String fullQuery) {
    var trimmedQuery = fullQuery;
    if (trimmedQuery.startsWith('?')) {
      trimmedQuery = trimmedQuery.substring(1);
    }
    clearLocationQuery();
    trimmedQuery.split('&').forEach(addLocationQuery);
  }

  /// Location queries
  List<LocationQueryOption> get locationQueries =>
      _selectOptions<LocationQueryOption>();

  /// Add a location query
  void addLocationQuery(final String query) =>
      addOption(LocationQueryOption(query));

  /// Remove a location query
  void removeLocationQuery(final String query) {
    _options.removeWhere(
      (final element) =>
          element is LocationQueryOption && element.value == query,
    );
  }

  /// Clear location  queries
  void clearLocationQuery() => removeOptions<LocationQueryOption>();

  /// Content type
  CoapMediaType? get contentType {
    final opt = getFirstOption<ContentFormatOption>();
    if (opt == null) {
      return null;
    }

    return CoapMediaType.fromIntValue(opt.value);
  }

  set contentType(final CoapMediaType? value) {
    if (value == null) {
      removeOptions<ContentFormatOption>();
    } else {
      setOption(ContentFormatOption(value.numericValue));
    }
  }

  /// The content-format of this CoAP message,
  /// Same as ContentType, only another name.
  CoapMediaType? get contentFormat => contentType;

  set contentFormat(final CoapMediaType? value) => contentType = value;

  /// The max-age of this CoAP message.
  int get maxAge {
    final opt = getFirstOption<MaxAgeOption>();
    return opt?.value ?? CoapConstants.defaultMaxAge;
  }

  set maxAge(final int value) => setOption(MaxAgeOption(value));

  /// Accept
  CoapMediaType? get accept {
    final opt = getFirstOption<AcceptOption>();
    if (opt == null) {
      return null;
    }

    return CoapMediaType.fromIntValue(opt.value);
  }

  set accept(final CoapMediaType? value) {
    if (value == null) {
      removeOptions<AcceptOption>();
    } else {
      setOption(AcceptOption(value.numericValue));
    }
  }

  /// Proxy uri
  Uri? get proxyUri {
    final opt = getFirstOption<ProxyUriOption>();
    if (opt == null) {
      return null;
    }
    var proxyUriString = opt.toString();
    if (!proxyUriString.startsWith('coap://') &&
        !proxyUriString.startsWith('coaps://') &&
        !proxyUriString.startsWith('http://') &&
        !proxyUriString.startsWith('https://')) {
      proxyUriString = 'coap://$proxyUriString';
    }
    return Uri.dataFromString(proxyUriString);
  }

  set proxyUri(final Uri? value) {
    if (value == null) {
      removeOptions<ProxyUriOption>();
    } else {
      setOption(ProxyUriOption(value.toString()));
    }
  }

  /// Proxy scheme
  String? get proxyScheme {
    final opt = getFirstOption<ProxySchemeOption>();
    return opt?.toString();
  }

  set proxyScheme(final String? value) {
    if (value == null) {
      removeOptions<ProxySchemeOption>();
    } else {
      setOption(ProxySchemeOption(value));
    }
  }

  /// Observe
  int? get observe => getFirstOption<ObserveOption>()?.value;

  @internal
  set observe(final int? value) {
    if (value == null) {
      removeOptions<ObserveOption>();
    } else {
      setOption(ObserveOption(value));
    }
  }

  /// Size 1
  int get size1 {
    final opt = getFirstOption<Size1Option>();
    return opt?.value ?? 0;
  }

  set size1(final int? value) {
    if (value == null) {
      removeOptions<Size1Option>();
    } else {
      setOption(Size1Option(value));
    }
  }

  /// Size 2
  int? get size2 {
    final opt = getFirstOption<Size2Option>();
    return opt?.value ?? 0;
  }

  set size2(final int? value) {
    if (value == null) {
      removeOptions<Size2Option>();
    } else {
      setOption(Size2Option(value));
    }
  }

  /// Block 1
  CoapBlockOption? get block1 => getFirstOption<Block1Option>();

  /// Block 1
  set block1(final CoapBlockOption? value) {
    if (value == null) {
      removeOptions<Block1Option>();
    } else {
      setOption(value);
    }
  }

  /// Block 1
  void setBlock1(final BlockSize szx, final int num, {required final bool m}) {
    setOption(
      Block1Option.fromParts(num, szx, m: m),
    );
  }

  /// Block 2
  CoapBlockOption? get block2 => getFirstOption<Block2Option>();

  set block2(final CoapBlockOption? value) {
    if (value == null) {
      removeOptions<Block2Option>();
    } else {
      setOption(value);
    }
  }

  /// Block 2
  void setBlock2(final BlockSize szx, final int num, {required final bool m}) {
    setOption(
      Block2Option.fromParts(num, szx, m: m),
    );
  }

  /// Copy an event handler
  void copyEventHandler(final CoapMessage msg) {
    acknowledgedHook = msg.acknowledgedHook;
    retransmittingHook = msg.retransmittingHook;
    timedOutHook = msg.timedOutHook;
  }

  @override
  String toString() => '\nType: ${type.toString()}, Code: $codeString, '
      'Id: ${id.toString()}, '
      "Token: '$tokenString',\n"
      'Options: ${_optionsToString()},\n'
      'Payload: $payloadString';

  String _optionsToString() {
    final sb = StringBuffer()
      ..writeln('[')
      ..write(_optionString('If-Match', ifMatches))
      ..write(_optionString('Uri Host', uriHost))
      ..write(_optionString('E-tags', etags))
      ..write(_optionString('If-None Match', ifNoneMatches))
      ..write(_optionString('Uri Port', uriPort > 0 ? uriPort : null))
      ..write(_optionString('Location Paths', locationPaths))
      ..write(_optionString('Uri Paths', uriPath))
      ..write(_optionString('Content-Type', contentType.toString()))
      ..write(_optionString('Max Age', maxAge))
      ..write(_optionString('Uri Queries', uriQueries));
    if (accept != null) {
      sb.write(_optionString('Accept', accept.toString()));
    }
    sb
      ..write(_optionString('Location Queries', locationQueries))
      ..write(_optionString('Proxy Uri', proxyUri))
      ..write(_optionString('Proxy Scheme', proxyScheme))
      ..write(_optionString('Block 1', block1))
      ..write(_optionString('Block 2', block2))
      ..write(_optionString('Observe', observe))
      ..write(_optionString('Size 1', size1))
      ..write(_optionString('Size 2', size2))
      ..write(']');
    return sb.toString();
  }

  String _optionString(final String name, final Object? value) {
    if (value == null) {
      return '';
    }
    var str = '';
    if (value is Iterable) {
      str = value.join(',');
    } else {
      str = value.toString();
    }
    return str != '' ? '  $name: $str,\n' : '';
  }

  /// Serializes this CoAP message from the UDP message format.
  ///
  /// Is also used for DTLS.
  static CoapMessage? fromUdpPayload(final Uint8Buffer data) =>
      deserializeUdpMessage(data);

  /// Serializes this CoAP message into the UDP message format.
  ///
  /// Is also used for DTLS.
  Uint8Buffer toUdpPayload() => serializeUdpMessage(this);

  /// Serializes this CoAP message from the TCP message format.
  ///
  /// Is also used for TLS.
  static CoapMessage? fromTcpPayload(final Uint8Buffer data) =>
      throw UnimplementedError(
        'TCP segment deserialization is not implemented yet.',
      );

  /// Serializes this CoAP message into the TCP message format.
  ///
  /// Is also used for TLS.
  Uint8Buffer toTcpPayload() => throw UnimplementedError(
        'TCP segment serialization is not implemented yet.',
      );
}
