/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/05/2017
 * Copyright :  S.Hamblett
 */

part of coap;

typedef HookFunction = void Function();

/// The class Message models the base class of all CoAP messages.
/// CoAP messages are of type Request, Response or EmptyMessage,
/// each of which has a MessageType, a message identifier,
/// a token (0-8 bytes), a collection of Options and a payload.
class CoapMessage {
  /// Default
  CoapMessage();

  /// Instantiates a message with the given type.
  CoapMessage.withType(this.type);

  /// Instantiates a message with the given type and code.
  CoapMessage.withCode(this.type, this.code);

  /// Indicates that no ID has been set.
  static const int none = -1;

  /// Initial message id limit
  static const int initialIdLimit = 32767;

  /// Invalid message ID.
  static const int invalidID = none;

  /// The type of this CoAP message.
  int type = CoapMessageType.unknown;

  /// The code of this CoAP message.
  int code = CoapCode.notSet;

  /// The codestring
  String get codeString => CoapCode.codeToString(code);

  static Random _initialId = Random();

  /// The ID of this CoAP message.
  int id = _initialId.nextInt(initialIdLimit) + 1;

  Map<int, List<CoapOption>> _optionMap = Map<int, List<CoapOption>>();
  CoapEventBus _eventBus = CoapEventBus();

  /// Option map
  Map<int, List<CoapOption>> get optionMap => _optionMap;

  /// Host name to resolve
  String resolveHost = 'localhost';

  /// Bind address if not using the default
  InternetAddress bindAddress;

  /// Adds an option to the list of options of this CoAP message.
  CoapMessage addOption(CoapOption option) {
    if (option == null) {
      throw ArgumentError.notNull('Message::addOption - option is null');
    }
    if (option.type == optionTypeToken) {
      // be compatible with draft 13-
      token = option.valueBytes;
      return this;
    }
    if (!_optionMap.containsKey(option.type)) {
      _optionMap[option.type] = List<CoapOption>();
    }
    _optionMap[option.type].add(option);
    return this;
  }

  /// Remove a specific option, returns true if the option has been removed.
  bool removeOption(CoapOption option) {
    bool ret = false;
    final List<CoapOption> options = getOptions(option.type);
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
  void addOptions(Iterable<CoapOption> options) {
    options.forEach(addOption);
  }

  /// Removes all options of the given type from this CoAP message.
  bool removeOptions(int optionType) {
    _optionMap.remove(optionType);
    return true;
  }

  /// Gets all options of the given type.
  Iterable<CoapOption> getOptions(int optionType) => _optionMap[optionType];

  /// Gets a list of all options.
  Iterable<CoapOption> getAllOptions() {
    final List<CoapOption> list = List<CoapOption>();
    for (Iterable<CoapOption> opts in _optionMap.values) {
      if (opts.isNotEmpty) {
        list.addAll(opts);
      }
    }
    return list;
  }

  /// Sets an option, removing all others of the option type
  void setOption(CoapOption opt) {
    if (opt != null) {
      removeOptions(opt.type);
      addOption(opt);
    }
  }

  /// Sets all options with the specified option type, removing all others of the same type
  void setOptions(Iterable<CoapOption> options) {
    if (options == null) {
      return;
    }
    for (CoapOption opt in options) {
      removeOptions(opt.type);
    }
    addOptions(options);
  }

  /// Returns the first option of the specified type, or null
  CoapOption getFirstOption(int optionType) {
    final List<CoapOption> options = getOptions(optionType);
    if (options == null) {
      return null;
    }
    for (CoapOption option in options) {
      if (option.type == optionType) {
        return option;
      }
    }
    return null;
  }

  /// Clear all options
  void clearOptions() => _optionMap.clear();

  /// Checks if this CoAP message has options of the specified option type.
  /// Returns true if options of the specified type exists.
  bool hasOption(int type) => getFirstOption(type) != null;

  typed.Uint8Buffer _token;

  /// The 0-8 byte token.
  typed.Uint8Buffer get token => _token;

  /// As a string
  String get tokenString =>
      _token != null ? CoapByteArrayUtil.toHexString(_token) : null;

  set token(typed.Uint8Buffer value) {
    if (value != null && value.length > 8) {
      throw ArgumentError.value(value, 'Message::token',
          'Token length must be between 0 and 8 inclusive.');
    }
    _token = value;
  }

  /// Gets a value that indicates whether this CoAP message is a request message.
  bool get isRequest => CoapCode.isRequest(code);

  /// Gets a value that indicates whether this CoAP message is a response message.
  bool get isResponse => CoapCode.isResponse(code);

  /// Gets a value that indicates whether this CoAP message is an empty message
  bool get isEmpty => CoapCode.isEmpty(code);

  /// Gets a value that indicates whether this CoAP message is a valid message
  bool get isValid => CoapCode.isValid(code);

  /// The destination endpoint.
  CoapInternetAddress destination;

  /// The source endpoint.
  CoapInternetAddress source;

  bool _acknowledged = false;

  /// Indicates whether this message has been acknowledged.
  bool get isAcknowledged => _acknowledged;

  /// Acknowledged hook for attaching a callback if needed
  HookFunction acknowledgedHook;

  set isAcknowledged(bool value) {
    _acknowledged = value;
    if (acknowledgedHook == null) {
      _eventBus.fire(CoapAcknowledgedEvent());
    } else {
      acknowledgedHook();
    }
  }

  bool _rejected = false;

  /// Indicates whether this message has been rejected.
  bool get isRejected => _rejected;

  set isRejected(bool value) {
    _rejected = value;
    _eventBus.fire(CoapRejectedEvent());
  }

  bool _timedOut = false;

  /// Indicates whether this message has been timed out.
  bool get isTimedOut => _timedOut;

  /// Timed out hook function for attaching a callback if needed
  HookFunction timedOutHook;

  set isTimedOut(bool value) {
    _timedOut = value;
    if (timedOutHook == null) {
      _eventBus.fire(CoapTimedOutEvent());
    } else {
      timedOutHook();
    }
  }

  /// Retransmit hook function
  HookFunction retransmittingHook;

  /// Fire retransmitting event
  void fireRetransmitting() {
    if (retransmittingHook != null) {
      retransmittingHook();
    }
  }

  bool _cancelled = false;

  /// Indicates whether this message has been cancelled.
  bool get isCancelled => _cancelled;

  set isCancelled(bool value) {
    _cancelled = value;
    _eventBus.fire(CoapCancelledEvent());
  }

  /// Indicates whether this message is a duplicate.
  bool duplicate = false;

  /// The serialized message as byte array, or null if not serialized yet.
  typed.Uint8Buffer bytes;

  /// The timestamp when this message has been received or sent,
  /// or null if neither has happened yet.
  DateTime timestamp;

  /// The max times this message should be retransmitted if no ACK received.
  /// A value of 0 means that the CoapConstants.maxRetransmit time
  /// shoud be taken into account, while a negative means NO retransmission.
  /// The default value is 0.
  int maxRetransmit = 0;

  /// The amount of time in milliseconds after which this message will time out.
  /// A value of 0 indicates that the time should be decided automatically from the
  /// configuration.
  /// The default value is 0.
  int ackTimeout = 0;

  /// UTF8 decoder and encoder helpers
  final convertor.Utf8Decoder _utfDecoder = const convertor.Utf8Decoder();
  final convertor.Utf8Encoder _utfEncoder = const convertor.Utf8Encoder();

  /// The payload of this CoAP message.
  typed.Uint8Buffer payload;

  /// The size of the payload of this CoAP message.
  int get payloadSize => null == payload ? 0 : payload.length;

  /// The payload of this CoAP message in string representation.
  String get payloadString {
    if (payload != null && payload.isNotEmpty) {
      try {
        final String ret = _utfDecoder.convert(payload);
        return ret;
      } on FormatException {
        // The payload may be incomplete, if so and the conversion fails indicate this
        return '<<<< Payload incomplete >>>>>';
      }
    }
    return null;
  }

  /// Sets the payload from a string with a default media type
  set payloadString(String value) =>
      setPayloadMedia(value, CoapMediaType.textPlain);

  /// Sets the payload.
  CoapMessage setPayload(String payload) {
    if (payload == null) {
      return this;
    }
    this.payload ??= typed.Uint8Buffer();
    this.payload.addAll(_utfEncoder.convert(payload));
    return this;
  }

  /// Sets the payload and media type of this CoAP message.
  CoapMessage setPayloadMedia(String payload, int mediaType) {
    if (payload == null) {
      return this;
    }
    this.payload ??= typed.Uint8Buffer();
    this.payload.addAll(_utfEncoder.convert(payload));
    contentType = mediaType;
    return this;
  }

  /// Sets the payload of this CoAP message.
  CoapMessage setPayloadMediaRaw(typed.Uint8Buffer payload, int mediaType) {
    this.payload = payload;
    contentType = mediaType;
    return this;
  }

  /// Cancels this message.
  void cancel() {
    isCancelled = true;
  }

  @override
  String toString() =>
      '\nType: ${type.toString()}, Code: $codeString, Id: ${id.toString()}, Token: $tokenString, \nOptions=[${CoapUtil.optionsToString(this)}], \nPayload :\n$payloadString';

  /// Select options helper
  Iterable<CoapOption> _selectOptions(int optionType) {
    final List<CoapOption> ret = List<CoapOption>();
    final Iterable<CoapOption> opts = getOptions(optionType);
    if (opts != null) {
      opts.forEach(ret.add);
    }
    return ret;
  }

  /// If-Matches.
  Iterable<CoapOption> get ifMatches =>
      _selectOptions(optionTypeIfMatch).toList();

  /// Add an if match option, if a null string is passed the if match is not set
  CoapMessage addIfMatch(String etag) {
    if (etag == null) {
      return this;
    }
    return addOption(CoapOption.createString(optionTypeIfMatch, etag));
  }

  /// Add an opaque if match
  CoapMessage addIfMatchOpaque(typed.Uint8Buffer opaque) {
    if (opaque == null) {
      throw ArgumentError.notNull('Message::addIfMatch');
    }
    if (opaque.length > 8) {
      throw ArgumentError.value(opaque.length, 'Message::addIfMatch',
          'Content of If-Match option is too large');
    }
    return addOption(CoapOption.createRaw(optionTypeIfMatch, opaque));
  }

  /// Remove an opaque if match
  CoapMessage removeIfMatchOpaque(typed.Uint8Buffer opaque) {
    final Iterable<CoapOption> list = getOptions(optionTypeIfMatch);
    if (list != null) {
      final CoapOption opt = CoapUtil.firstOrDefault(list,
          (CoapOption o) => CoapUtil.areSequenceEqualTo(opaque, o.valueBytes));
      if (opt != null) {
        _optionMap[optionTypeIfMatch].remove(opt);
        if (_optionMap[optionTypeIfMatch].isEmpty) {
          _optionMap.remove(optionTypeIfMatch);
        }
      }
    }
    return this;
  }

  /// Remove an if match option
  CoapMessage removeIfMatch(CoapOption option) {
    if (option.type != optionTypeIfMatch) {
      throw ArgumentError.value(
          option.type, 'Message::removeIfMatch', 'Not an if match option');
    }
    removeOption(option);
    return this;
  }

  /// Clear the if matches
  CoapMessage clearIfMatches() {
    removeOptions(optionTypeIfMatch);
    return this;
  }

  /// Etags
  Iterable<CoapOption> get etags => _selectOptions(optionTypeETag).toList();

  /// Contains an opaque E-tag
  bool containsETagOpaque(typed.Uint8Buffer what) =>
      CoapUtil.contains(
      getOptions(optionTypeETag),
      (CoapOption o) => CoapUtil.areSequenceEqualTo(what, o.valueBytes));

  /// Add an opaque ETag
  CoapMessage addETagOpaque(typed.Uint8Buffer opaque) {
    if (opaque == null) {
      throw ArgumentError.notNull('Message::addETag');
    }
    return addOption(CoapOption.createRaw(optionTypeETag, opaque));
  }

  /// Adds an ETag option
  CoapMessage addEtag(CoapOption option) {
    if (option.type != optionTypeETag) {
      throw ArgumentError.notNull('Message::addETag, option is not an etag');
    }
    return addOption(option);
  }

  /// Remove an ETag, true indicates success
  bool removeEtag(CoapOption option) {
    if (option.type != optionTypeETag) {
      throw ArgumentError.notNull('Message::removeETag, option is not an etag');
    }
    return removeOption(option);
  }

  /// Remove an opaque ETag
  CoapMessage removeETagOpaque(typed.Uint8Buffer opaque) {
    final List<CoapOption> list = getOptions(optionTypeETag);
    if (list != null) {
      const collection.Equality<typed.Uint8Buffer> equality =
      collection.Equality<typed.Uint8Buffer>();
      final CoapOption opt = CoapUtil.firstOrDefault(
          list,
              (CoapOption o) =>
              CoapUtil.areSequenceEqualTo(opaque, o.valueBytes, equality));
      if (opt != null) {
        _optionMap[optionTypeETag].remove(opt);
        if (_optionMap[optionTypeETag].isEmpty) {
          _optionMap.remove(optionTypeETag);
        }
      }
    }
    return this;
  }

  /// Clear the E tags
  CoapMessage clearETags() {
    removeOptions(optionTypeETag);
    return this;
  }

  /// IfNoneMatch
  bool get ifNoneMatch => hasOption(optionTypeIfNoneMatch);

  set ifNoneMatch(bool value) {
    if (value) {
      CoapOption.create(optionTypeIfNoneMatch);
    } else {
      removeOptions(optionTypeIfNoneMatch);
    }
  }

  /// Uri's
  String get uriHost {
    final CoapOption host = getFirstOption(optionTypeUriHost);
    return host == null ? null : host.toString();
  }

  set uriHost(String value) {
    if (value == null) {
      throw ArgumentError.notNull('Message::uriHost');
    }
    if (value.isEmpty || value.length > 255) {
      throw ArgumentError.value(value.length, 'Message::uriHost',
          'URI-Host option\'s length must be between 1 and 255 inclusive');
    }
    setOption(CoapOption.createString(optionTypeUriHost, value));
  }

  /// URI path
  String get uriPath {
    String join = CoapOption.join(getOptions(optionTypeUriPath), '/');
    return join += '/';
  }

  set uriPath(String value) =>
      setOptions(CoapOption.split(optionTypeUriPath, value, '/'));

  /// URI paths
  Iterable<String> get uriPaths sync* {
    final Iterable<CoapOption> opts = getOptions(optionTypeUriPath);
    if (opts != null) {
      for (CoapOption opt in opts) {
        yield opt.toString();
      }
    }
  }

  /// Add a URI path
  CoapMessage addUriPath(String path) {
    if (path == null) {
      throw ArgumentError.notNull('Message::addUriPath');
    }
    if (path.length > 255) {
      throw ArgumentError.value(path.length, 'Message::addUriPath',
          'Uri Path option\'s length must be between 0 and 255 inclusive');
    }
    return addOption(CoapOption.createString(optionTypeUriPath, path));
  }

  /// Remove a URI path
  CoapMessage removeUriPath(String path) {
    final List<CoapOption> list = getOptions(optionTypeUriPath);
    if (list != null) {
      final CoapOption opt =
          CoapUtil.firstOrDefault(list, (CoapOption o) => path == o.toString());
      if (opt != null) {
        list.remove(opt);
      }
    }
    return this;
  }

  /// Clear URI paths
  CoapMessage clearUriPath() {
    removeOptions(optionTypeUriPath);
    return this;
  }

  /// URI query
  String get uriQuery => CoapOption.join(getOptions(optionTypeUriQuery), '&');

  set uriQuery(String value) {
    String tmp = value;
    if (value.isNotEmpty && value.startsWith('?')) {
      tmp = value.substring(1);
    }
    setOptions(CoapOption.split(optionTypeUriQuery, tmp, '&'));
  }

  /// URI queries
  Iterable<String> get uriQueries sync* {
    final Iterable<CoapOption> opts = getOptions(optionTypeUriQuery);
    if (opts != null) {
      for (CoapOption opt in opts) {
        yield opt.toString();
      }
    }
  }

  /// Add a URI query
  CoapMessage addUriQuery(String query) {
    if (query == null) {
      throw ArgumentError.notNull('Message::addUriQuery');
    }
    if (query.length > 255) {
      throw ArgumentError.value(query.length, 'Message::addUriQuery',
          'Uri Query option\'s length must be between 0 and 255 inclusive');
    }
    return addOption(CoapOption.createString(optionTypeUriQuery, query));
  }

  /// Remove a URI query
  CoapMessage removeUriQuery(String query) {
    final List<CoapOption> list = getOptions(optionTypeUriQuery);
    if (list != null) {
      final CoapOption opt = CoapUtil.firstOrDefault(
          list, (CoapOption o) => query == o.toString());
      if (opt != null) {
        list.remove(opt);
      }
    }
    return this;
  }

  /// Clear URI queries
  CoapMessage clearUriQuery() {
    removeOptions(optionTypeUriQuery);
    return this;
  }

  /// Uri port
  int get uriPort {
    final CoapOption opt = getFirstOption(optionTypeUriPort);
    return opt == null ? null : opt.value;
  }

  set uriPort(int value) {
    if (value == 0) {
      removeOptions(optionTypeUriPort);
    } else {
      setOption(CoapOption.createVal(optionTypeUriPort, value));
    }
  }

  /// Location
  String get locationPath =>
      CoapOption.join(getOptions(optionTypeLocationPath), '/');

  set locationPath(String value) =>
      setOptions(CoapOption.split(optionTypeLocationPath, value, '/'));

  /// Location paths
  Iterable<CoapOption> get locationPaths =>
      _selectOptions(optionTypeLocationPath);

  /// Location
  String get location {
    String path = '/$locationPath';
    final String query = locationQuery;
    if (query.isNotEmpty) {
      path += '?$query';
    }
    return path;
  }

  /// Add a location path
  CoapMessage addLocationPath(String path) {
    if (path == null) {
      throw ArgumentError.notNull('Message::addLocationPath');
    }
    if (path.length > 255) {
      throw ArgumentError.value(path.length, 'Message::addLocationPath',
          'Location Path option\'s length must be between 0 and 255 inclusive');
    }
    return addOption(CoapOption.createString(optionTypeLocationPath, path));
  }

  /// Remove a location path
  CoapMessage removelocationPath(String path) {
    final List<CoapOption> list = getOptions(optionTypeLocationPath);
    if (list != null) {
      final CoapOption opt =
          CoapUtil.firstOrDefault(list, (CoapOption o) => path == o.toString());
      if (opt != null) {
        list.remove(opt);
      }
    }
    return this;
  }

  /// Clear location path
  CoapMessage clearLocationPath() {
    removeOptions(optionTypeLocationPath);
    return this;
  }

  /// Location query
  String get locationQuery =>
      CoapOption.join(getOptions(optionTypeLocationQuery), '&');

  set locationQuery(String value) {
    String tmp = value;
    if (value.isNotEmpty && value.startsWith('?')) {
      tmp = value.substring(1);
    }
    setOptions(CoapOption.split(optionTypeLocationQuery, tmp, '&'));
  }

  /// Location queries
  Iterable<CoapOption> get locationQueries =>
      _selectOptions(optionTypeLocationQuery);

  /// Add a location query
  CoapMessage addLocationQuery(String query) {
    if (query == null) {
      throw ArgumentError.notNull('Message::addLocationQuery');
    }
    if (query.length > 255) {
      throw ArgumentError.value(query.length, 'Message::addLocationQuery',
          'Location Query option\'s length must be between 0 and 255 inclusive');
    }
    return addOption(CoapOption.createString(optionTypeLocationQuery, query));
  }

  /// Remove a location query
  CoapMessage removeLocationQuery(String query) {
    final List<CoapOption> list = getOptions(optionTypeLocationQuery);
    if (list != null) {
      final CoapOption opt = CoapUtil.firstOrDefault(
          list, (CoapOption o) => query == o.toString());
      if (opt != null) {
        list.remove(opt);
      }
    }
    return this;
  }

  /// Clear location queries
  CoapMessage clearLocationQuery() {
    removeOptions(optionTypeLocationQuery);
    return this;
  }

  /// Content type
  int get contentType {
    final CoapOption opt = getFirstOption(optionTypeContentType);
    return (null == opt) ? CoapMediaType.undefined : opt.value;
  }

  set contentType(int value) {
    if (value == CoapMediaType.undefined) {
      removeOptions(optionTypeContentType);
    } else {
      setOption(CoapOption.createVal(optionTypeContentType, value));
    }
  }

  /// The content-format of this CoAP message,
  /// Same as ContentType, only another name.
  int get contentFormat => contentType;

  set contentFormat(int value) => contentType = value;

  /// The max-age of this CoAP message.
  int get maxAge {
    final CoapOption opt = getFirstOption(optionTypeMaxAge);
    return (null == opt) ? CoapConstants.defaultMaxAge : opt.value;
  }

  set maxAge(int value) {
    if (value < 0 || value > 4294967295) {
      throw ArgumentError.value(value, 'Message::maxAge',
          'Max-Age option must be between 0 and 4294967295 (4 bytes) inclusive');
    }
    setOption(CoapOption.createVal(optionTypeMaxAge, value));
  }

  /// Accept
  int get accept {
    final CoapOption opt = getFirstOption(optionTypeAccept);
    return (null == opt) ? CoapMediaType.undefined : opt.value;
  }

  set accept(int value) {
    if (value == CoapMediaType.undefined) {
      removeOptions(optionTypeAccept);
    } else {
      setOption(CoapOption.createVal(optionTypeAccept, value));
    }
  }

  /// Proxy uri
  Uri get proxyUri {
    final CoapOption opt = getFirstOption(optionTypeProxyUri);
    if (opt == null) {
      return null;
    }
    String proxyUriString = opt.toString();
    if (!proxyUriString.startsWith('coap://') &&
        !proxyUriString.startsWith('coaps://') &&
        !proxyUriString.startsWith('http://') &&
        !proxyUriString.startsWith('https://')) {
      proxyUriString = 'coap://$proxyUriString';
    }
    return Uri.dataFromString(proxyUriString);
  }

  set proxyUri(Uri value) {
    if (value == null) {
      removeOptions(optionTypeProxyUri);
    } else {
      setOption(CoapOption.createString(optionTypeProxyUri, value.toString()));
    }
  }

  /// Proxy scheme
  String get proxyScheme {
    final CoapOption opt = getFirstOption(optionTypeProxyScheme);
    return opt == null ? null : opt.toString();
  }

  set proxyScheme(String value) {
    if (value == null) {
      removeOptions(optionTypeProxyScheme);
    } else {
      setOption(CoapOption.createString(optionTypeProxyScheme, value));
    }
  }

  /// Observe
  int get observe {
    final CoapOption opt = getFirstOption(optionTypeObserve);
    if (opt == null) {
      return -1;
    } else {
      return opt.value;
    }
  }

  set observe(int value) {
    if (value == null) {
      removeOptions(optionTypeObserve);
    } else if (value < 0 || ((1 << 24) - 1) < value) {
      throw ArgumentError.value(value, 'Message::observe',
          'Observe option must be between 0 and ${(1 << 24) - 1} (3 bytes) inclusive');
    } else {
      setOption(CoapOption.createVal(optionTypeObserve, value));
    }
  }

  /// Size 1
  int get size1 {
    final CoapOption opt = getFirstOption(optionTypeSize1);
    return opt == null ? 0 : opt.value;
  }

  set size1(int value) {
    if (value == null) {
      removeOptions(optionTypeSize1);
    } else {
      setOption(CoapOption.createVal(optionTypeSize1, value));
    }
  }

  /// Size 2
  int get size2 {
    final CoapOption opt = getFirstOption(optionTypeSize2);
    return opt == null ? 0 : opt.value;
  }

  set size2(int value) {
    if (value == null) {
      removeOptions(optionTypeSize2);
    } else {
      setOption(CoapOption.createVal(optionTypeSize2, value));
    }
  }

  /// Block 1
  CoapBlockOption get block1 => getFirstOption(optionTypeBlock1);

  set block1(CoapBlockOption value) {
    if (value == null) {
      removeOptions(optionTypeBlock1);
    } else {
      setOption(value);
    }
  }

  /// Block 1
  void setBlock1(int szx, int num, {bool m}) {
    setOption(CoapBlockOption.fromParts(optionTypeBlock1, num, szx, m: m));
  }

  /// Block 2
  CoapBlockOption get block2 => getFirstOption(optionTypeBlock2);

  set block2(CoapBlockOption value) {
    if (value == null) {
      removeOptions(optionTypeBlock2);
    } else {
      setOption(value);
    }
  }

  /// Block 2
  void setBlock2(int szx, int num, {bool m}) {
    setOption(CoapBlockOption.fromParts(optionTypeBlock2, num, szx, m: m));
  }

  /// Copy an event handler
  void copyEventHandler(CoapMessage msg) {
    acknowledgedHook = msg.acknowledgedHook;
    retransmittingHook = msg.retransmittingHook;
    timedOutHook = msg.timedOutHook;
  }
}
