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

import 'coap_block_option.dart';
import 'coap_code.dart';
import 'coap_constants.dart';
import 'coap_media_type.dart';
import 'coap_message_type.dart';
import 'coap_option.dart';
import 'coap_option_type.dart';
import 'event/coap_event_bus.dart';
import 'util/coap_byte_array_util.dart';

typedef HookFunction = void Function();

/// The class Message models the base class of all CoAP messages.
/// CoAP messages are of type Request, Response or EmptyMessage,
/// each of which has a MessageType, a message identifier,
/// a token (0-8 bytes), a collection of Options and a payload.
abstract class CoapMessage {
  CoapMessage(this.code, this._type);

  bool hasUnknownCriticalOption = false;

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

  final Map<OptionType, List<CoapOption>> _optionMap = {};
  CoapEventBus? _eventBus = CoapEventBus(namespace: '');

  /// Option map
  Map<OptionType, List<CoapOption>> get optionMap => _optionMap;

  /// Host name to resolve
  String resolveHost = 'localhost';

  /// Bind address if not using the default
  InternetAddress? bindAddress;

  @internal
  set eventBus(final CoapEventBus? eventBus) => _eventBus = eventBus;

  CoapEventBus? get eventBus => _eventBus;

  String? get namespace => _eventBus?.namespace;

  /// Adds an option to the list of options of this CoAP message.
  void addOption(final CoapOption option) =>
      _optionMap[option.type] = (_optionMap[option.type] ?? [])..add(option);

  /// Remove a specific option, returns true if the option has been removed.
  bool removeOption(final CoapOption option) {
    var ret = false;
    final options = getOptions(option.type);
    if (options == null) {
      return ret;
    }
    ret = options.remove(option);
    if (ret) {
      setOptions(options);
    }
    return ret;
  }

  /// Adds options to the list of options of this CoAP message.
  void addOptions(final Iterable<CoapOption> options) =>
      options.forEach(addOption);

  /// Removes all options of the given type from this CoAP message.
  void removeOptions(final OptionType optionType) =>
      _optionMap.remove(optionType);

  /// Gets all options of the given type.
  List<CoapOption>? getOptions(final OptionType optionType) =>
      _optionMap[optionType];

  /// Gets a list of all options.
  List<CoapOption> getAllOptions() {
    final list = <CoapOption>[];
    for (final Iterable<CoapOption> opts in _optionMap.values) {
      if (opts.isNotEmpty) {
        list.addAll(opts);
      }
    }
    return list;
  }

  /// Sets an option, removing all others of the option type
  void setOption(final CoapOption opt) => _optionMap[opt.type] = [opt];

  /// Sets all options with the specified option type, removing
  /// all others of the same type.
  void setOptions(final Iterable<CoapOption> options) {
    for (final opt in options) {
      removeOptions(opt.type);
    }
    addOptions(options);
  }

  /// Returns the first option of the specified type, or null
  CoapOption? getFirstOption(final OptionType optionType) =>
      getOptions(optionType)
          ?.firstWhereOrNull((final element) => element.type == optionType);

  /// Clear all options
  void clearOptions() => _optionMap.clear();

  /// Checks if this CoAP message has options of the specified option type.
  /// Returns true if options of the specified type exists.
  bool hasOption(final OptionType type) => getFirstOption(type) != null;

  Uint8Buffer? _token;

  /// The 0-8 byte token.
  Uint8Buffer? get token => _token;

  /// As a string
  String get tokenString {
    final token = _token;
    return token != null ? CoapByteArrayUtil.toHexString(token) : '';
  }

  set token(final Uint8Buffer? value) {
    if (value != null && value.length > 8) {
      throw ArgumentError.value(
        value,
        'Message::token',
        'Token length must be between 0 and 8 inclusive.',
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

  Uint8Buffer? _bytes;

  /// The serialized message as byte array, or null if not serialized yet.
  Uint8Buffer? get bytes => _bytes;
  @internal
  set bytes(final Uint8Buffer? val) => _bytes = val;

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
  String? get payloadString {
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
    return null;
  }

  /// Sets the payload from a string with a default media type
  set payloadString(final String? value) =>
      setPayloadMedia(value, CoapMediaType.textPlain);

  /// Sets the payload.
  void setPayload(final String payload) {
    this.payload ??= Uint8Buffer();
    this.payload!.addAll(_utfEncoder.convert(payload));
  }

  /// Sets the payload and media type of this CoAP message.
  void setPayloadMedia(final String? payload, final CoapMediaType mediaType) {
    if (payload == null) {
      return;
    }
    this.payload ??= Uint8Buffer();
    this.payload!.addAll(_utfEncoder.convert(payload));
    contentType = mediaType;
  }

  /// Sets the payload of this CoAP message.
  void setPayloadMediaRaw(
    final Uint8Buffer payload,
    final CoapMediaType mediaType,
  ) {
    this.payload = payload;
    contentType = mediaType;
  }

  /// Select options helper
  List<CoapOption> _selectOptions(final OptionType optionType) =>
      getOptions(optionType) ?? [];

  /// If-Matches.
  List<CoapOption> get ifMatches => _selectOptions(OptionType.ifMatch);

  /// Add an if match option, if a null string is passed the if match is not set
  void addIfMatch(final String etag) =>
      addOption(CoapOption.createString(OptionType.ifMatch, etag));

  /// Add an opaque if match
  void addIfMatchOpaque(final Uint8Buffer opaque) {
    if (opaque.length > 8) {
      throw ArgumentError.value(
        opaque.length,
        'Message::addIfMatch',
        'Content of If-Match option is too large',
      );
    }
    addOption(CoapOption.createRaw(OptionType.ifMatch, opaque));
  }

  /// Remove an opaque if match
  void removeIfMatchOpaque(final Uint8Buffer opaque) {
    final opts = _optionMap[OptionType.ifMatch]
      ?..removeWhere((final o) => o.byteValue.equals(opaque));
    if (opts != null && opts.isEmpty) {
      _optionMap.remove(OptionType.ifMatch);
    }
  }

  /// Remove an if match option
  void removeIfMatch(final CoapOption option) {
    if (option.type != OptionType.ifMatch) {
      throw ArgumentError.value(
        option.type,
        'Message::removeIfMatch',
        'Not an if match option',
      );
    }
    removeOption(option);
  }

  /// Clear the if matches
  void clearIfMatches() {
    removeOptions(OptionType.ifMatch);
  }

  /// Etags
  List<CoapOption> get etags => _selectOptions(OptionType.eTag);

  /// Contains an opaque E-tag
  bool containsETagOpaque(final Uint8Buffer opaque) =>
      getOptions(OptionType.eTag)
          ?.firstWhereOrNull((final o) => o.byteValue.equals(opaque)) !=
      null;

  /// Add an opaque ETag
  void addETagOpaque(final Uint8Buffer opaque) {
    addOption(CoapOption.createRaw(OptionType.eTag, opaque));
  }

  /// Adds an ETag option
  void addEtag(final CoapOption option) {
    if (option.type != OptionType.eTag) {
      throw ArgumentError.notNull('Message::addETag, option is not an etag');
    }
    addOption(option);
  }

  /// Remove an ETag, true indicates success
  bool removeEtag(final CoapOption option) {
    if (option.type != OptionType.eTag) {
      throw ArgumentError.notNull('Message::removeETag, option is not an etag');
    }
    return removeOption(option);
  }

  /// Remove an opaque ETag
  void removeETagOpaque(final Uint8Buffer opaque) {
    final opts = _optionMap[OptionType.eTag];
    opts?.removeWhere((final o) => o.byteValue.equals(opaque));
    if (opts != null && opts.isEmpty) {
      _optionMap.remove(OptionType.eTag);
    }
  }

  /// Clear the E tags
  void clearETags() => removeOptions(OptionType.eTag);

  /// If-None Matches.
  List<CoapOption> get ifNoneMatches => _selectOptions(OptionType.ifNoneMatch);

  /// Add an if none match option
  void addIfNoneMatch(final CoapOption option) {
    if (option.type != OptionType.ifNoneMatch) {
      throw ArgumentError.value(
        'Message::addIfNoneMatch',
        'Option is not an if none match',
      );
    }
    addOption(option);
  }

  /// Add an opaque if none match
  void addIfNoneMatchOpaque(final Uint8Buffer opaque) {
    if (opaque.length > 8) {
      throw ArgumentError.value(
        opaque.length,
        'Message::addIfNoneMatch',
        'Content of If-None Match option is too large',
      );
    }
    addOption(CoapOption.createRaw(OptionType.ifNoneMatch, opaque));
  }

  /// Remove an opaque if none match
  void removeIfNoneMatchOpaque(final Uint8Buffer opaque) {
    final opts = _optionMap[OptionType.ifNoneMatch];
    opts?.removeWhere((final o) => o.byteValue.equals(opaque));
    if (opts != null && opts.isEmpty) {
      _optionMap.remove(OptionType.ifNoneMatch);
    }
  }

  /// Remove an if none match option
  void removeIfNoneMatch(final CoapOption option) {
    if (option.type != OptionType.ifNoneMatch) {
      throw ArgumentError.value(
        option.type,
        'Message::removeIfNoneMatch',
        'Not an if none match option',
      );
    }
    removeOption(option);
  }

  /// Clear the if none matches
  void clearIfNoneMatches() => removeOptions(OptionType.ifNoneMatch);

  /// Uri's
  String? get uriHost {
    final host = getFirstOption(OptionType.uriHost);
    return host?.toString();
  }

  @internal
  set uriHost(final String? value) {
    if (value == null) {
      throw ArgumentError.notNull('Message::uriHost');
    }
    if (value.isEmpty || value.length > 255) {
      throw ArgumentError.value(
        value.length,
        'Message::uriHost',
        "URI-Host option's length must be between 1 and 255 inclusive",
      );
    }
    setOption(CoapOption.createString(OptionType.uriHost, value));
  }

  /// URI path
  String get uriPath =>
      CoapOption.join(getOptions(OptionType.uriPath), '/') ?? '';

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
  List<CoapOption> get uriPaths => _selectOptions(OptionType.uriPath);

  /// Add a URI path
  void addUriPath(final String path) {
    final trimmedPath = _trimChar(path, '/');
    if (trimmedPath.contains('/')) {
      throw ArgumentError.value(
        path,
        'Message::addUriPath',
        'A single Uri Path can only contain leading or trailing slashes',
      );
    }
    if (trimmedPath.length > 255) {
      throw ArgumentError.value(
        trimmedPath.length,
        'Message::addUriPath',
        "Uri Path option's length must be between 0 and 255 inclusive",
      );
    }
    addOption(CoapOption.createString(OptionType.uriPath, trimmedPath));
  }

  /// Remove a URI path
  void removeUriPath(final String path) {
    final opts = _optionMap[OptionType.uriPath];
    opts?.removeWhere((final o) => o.stringValue == path);
    if (opts != null && opts.isEmpty) {
      _optionMap.remove(OptionType.uriPath);
    }
  }

  /// Clear URI paths
  void clearUriPath() => removeOptions(OptionType.uriPath);

  /// URI query
  String get uriQuery =>
      CoapOption.join(getOptions(OptionType.uriQuery), '&') ?? '';

  /// Set a URI query
  set uriQuery(final String fullQuery) {
    var trimmedQuery = _trimChar(fullQuery, '&');
    if (trimmedQuery.startsWith('?')) {
      trimmedQuery = trimmedQuery.substring(1);
    }
    clearUriQuery();
    trimmedQuery.split('&').forEach(addUriQuery);
  }

  /// URI queries
  List<CoapOption> get uriQueries => _selectOptions(OptionType.uriQuery);

  /// Add a URI query
  void addUriQuery(final String query) {
    final trimmedQuery = _trimChar(query, '&');
    if (trimmedQuery.contains('&')) {
      throw ArgumentError.value(
        query,
        'Message::addUriQuery',
        'A single Uri Query can only contain leading or trailing &',
      );
    }
    if (trimmedQuery.length > 255) {
      throw ArgumentError.value(
        trimmedQuery.length,
        'Message::addUriQuery',
        "Uri Query option's length must be between 0 and 255 inclusive",
      );
    }
    addOption(CoapOption.createUriQuery(query));
  }

  /// Remove a URI query
  void removeUriQuery(final String query) {
    final opts = _optionMap[OptionType.uriQuery];
    opts?.removeWhere((final o) => o.stringValue == query);
    if (opts != null && opts.isEmpty) {
      _optionMap.remove(OptionType.uriQuery);
    }
  }

  /// Clear URI queries
  void clearUriQuery() => removeOptions(OptionType.uriQuery);

  /// Uri port
  int get uriPort => getFirstOption(OptionType.uriPort)?.value as int? ?? 0;

  set uriPort(final int value) {
    if (value == 0) {
      removeOptions(OptionType.uriPort);
    } else {
      setOption(CoapOption.createVal(OptionType.uriPort, value));
    }
  }

  /// Location path as a string
  String get locationPath {
    final sb = StringBuffer();
    for (final option in locationPaths) {
      sb.write(option.stringValue);
      if (option != locationPaths.last) {
        sb.write('/');
      }
    }
    return sb.toString();
  }

  /// Set the location path from a string
  set locationPath(final String fullPath) {
    final trimmedPath = _trimChar(fullPath, '/');
    clearLocationPath();
    trimmedPath.split('/').forEach(addLocationPath);
  }

  /// Location paths
  List<CoapOption> get locationPaths => _selectOptions(OptionType.locationPath);

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
  void addLocationPath(final String path) {
    final trimmedPath = _trimChar(path, '/');
    if (trimmedPath == '..' || trimmedPath == '.') {
      throw ArgumentError.value(
        path,
        'Message::addLocationPath'
        "A Location Path must not be only '.' or '..'",
      );
    }
    if (trimmedPath.contains('/')) {
      throw ArgumentError.value(
        path,
        'Message::addLocationPath',
        'A single Location Path can only contain leading or trailing slashes',
      );
    }
    if (trimmedPath.length > 255) {
      throw ArgumentError.value(
        trimmedPath.length,
        'Message::addLocationPath',
        "Location Path option's length must be between 0 and 255 inclusive",
      );
    }
    addOption(CoapOption.createString(OptionType.locationPath, trimmedPath));
  }

  /// Remove a location path
  void removelocationPath(final String path) {
    final opts = _optionMap[OptionType.locationPath];
    opts?.removeWhere((final o) => o.stringValue == path);
    if (opts != null && opts.isEmpty) {
      _optionMap.remove(OptionType.locationPath);
    }
  }

  /// Clear location path
  void clearLocationPath() => _optionMap.remove(OptionType.locationPath);

  /// Location query
  String get locationQuery =>
      CoapOption.join(getOptions(OptionType.locationQuery), '&') ?? '';

  /// Set a location query
  set locationQuery(final String fullQuery) {
    var trimmedQuery = _trimChar(fullQuery, '&');
    if (trimmedQuery.startsWith('?')) {
      trimmedQuery = trimmedQuery.substring(1);
    }
    clearLocationQuery();
    trimmedQuery.split('&').forEach(addLocationQuery);
  }

  /// Location queries
  List<CoapOption> get locationQueries =>
      _selectOptions(OptionType.locationQuery);

  /// Add a location query
  void addLocationQuery(final String query) {
    final trimmedQuery = _trimChar(query, '&');
    if (trimmedQuery.length > 255) {
      throw ArgumentError.value(
        trimmedQuery.length,
        'Message::addLocationQuery',
        "Location Query option's length must be between "
            '0 and 255 inclusive',
      );
    }
    if (trimmedQuery.contains('&')) {
      throw ArgumentError.value(
        query,
        'Message::addLocationQuery',
        'A single Location Query can only contain leading or trailing &',
      );
    }
    addOption(CoapOption.createString(OptionType.locationQuery, query));
  }

  /// Remove a location query
  void removeLocationQuery(final String query) {
    final opts = _optionMap[OptionType.locationQuery];
    opts?.removeWhere((final o) => o.stringValue == query);
    if (opts != null && opts.isEmpty) {
      _optionMap.remove(OptionType.locationQuery);
    }
  }

  /// Clear location  queries
  void clearLocationQuery() => removeOptions(OptionType.locationQuery);

  /// Content type
  CoapMediaType? get contentType {
    final opt = getFirstOption(OptionType.contentFormat);
    if (opt == null) {
      return null;
    }

    return CoapMediaType.fromIntValue(opt.intValue);
  }

  set contentType(final CoapMediaType? value) {
    if (value == null) {
      removeOptions(OptionType.contentFormat);
    } else {
      setOption(
        CoapOption.createVal(OptionType.contentFormat, value.numericValue),
      );
    }
  }

  /// The content-format of this CoAP message,
  /// Same as ContentType, only another name.
  CoapMediaType? get contentFormat => contentType;

  set contentFormat(final CoapMediaType? value) => contentType = value;

  /// The max-age of this CoAP message.
  int get maxAge {
    final opt = getFirstOption(OptionType.maxAge);
    return opt?.value as int? ?? CoapConstants.defaultMaxAge;
  }

  set maxAge(final int value) {
    if (value < 0 || value > 4294967295) {
      throw ArgumentError.value(
        value,
        'Message::maxAge',
        'Max-Age option must be between 0 and 4294967295 '
            '(4 bytes) inclusive',
      );
    }
    setOption(CoapOption.createVal(OptionType.maxAge, value));
  }

  /// Accept
  CoapMediaType? get accept {
    final opt = getFirstOption(OptionType.accept);
    if (opt == null) {
      return null;
    }

    return CoapMediaType.fromIntValue(opt.intValue);
  }

  set accept(final CoapMediaType? value) {
    if (value == null) {
      removeOptions(OptionType.accept);
    } else {
      setOption(CoapOption.createVal(OptionType.accept, value.numericValue));
    }
  }

  /// Proxy uri
  Uri? get proxyUri {
    final opt = getFirstOption(OptionType.proxyUri);
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
      removeOptions(OptionType.proxyUri);
    } else {
      setOption(CoapOption.createString(OptionType.proxyUri, value.toString()));
    }
  }

  /// Proxy scheme
  String? get proxyScheme {
    final opt = getFirstOption(OptionType.proxyScheme);
    return opt?.toString();
  }

  set proxyScheme(final String? value) {
    if (value == null) {
      removeOptions(OptionType.proxyScheme);
    } else {
      setOption(CoapOption.createString(OptionType.proxyScheme, value));
    }
  }

  /// Observe
  int? get observe {
    final opt = getFirstOption(OptionType.observe);
    return opt?.value as int?;
  }

  @internal
  set observe(final int? value) {
    if (value == null) {
      removeOptions(OptionType.observe);
    } else if (value < 0 || ((1 << 24) - 1) < value) {
      throw ArgumentError.value(
        value,
        'Message::observe',
        'Observe option must be between 0 and '
            '${(1 << 24) - 1} (3 bytes) inclusive',
      );
    } else {
      setOption(CoapOption.createVal(OptionType.observe, value));
    }
  }

  /// Size 1
  int get size1 {
    final opt = getFirstOption(OptionType.size1);
    return opt?.value as int? ?? 0;
  }

  set size1(final int? value) {
    if (value == null) {
      removeOptions(OptionType.size1);
    } else {
      setOption(CoapOption.createVal(OptionType.size1, value));
    }
  }

  /// Size 2
  int? get size2 {
    final opt = getFirstOption(OptionType.size2);
    return opt?.value as int? ?? 0;
  }

  set size2(final int? value) {
    if (value == null) {
      removeOptions(OptionType.size2);
    } else {
      setOption(CoapOption.createVal(OptionType.size2, value));
    }
  }

  /// Block 1
  CoapBlockOption? get block1 =>
      getFirstOption(OptionType.block1) as CoapBlockOption?;

  /// Block 1
  set block1(final CoapBlockOption? value) {
    if (value == null) {
      removeOptions(OptionType.block1);
    } else {
      setOption(value);
    }
  }

  /// Block 1
  void setBlock1(final int szx, final int num, {required final bool m}) {
    setOption(CoapBlockOption.fromParts(OptionType.block1, num, szx, m: m));
  }

  /// Block 2
  CoapBlockOption? get block2 =>
      getFirstOption(OptionType.block2) as CoapBlockOption?;

  set block2(final CoapBlockOption? value) {
    if (value == null) {
      removeOptions(OptionType.block2);
    } else {
      setOption(value);
    }
  }

  /// Block 2
  void setBlock2(final int szx, final int num, {required final bool m}) {
    setOption(CoapBlockOption.fromParts(OptionType.block2, num, szx, m: m));
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

  String _trimChar(final String str, final String char) {
    var trimmed = str;
    if (trimmed.startsWith(char)) {
      trimmed = trimmed.substring(1);
    }

    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }

    return trimmed;
  }
}
