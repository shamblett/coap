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
  /// Constructor
  CoapMessage(
      {this.type = CoapMessageType.unknown, this.code = CoapCode.notSet});

  /// Indicates that no ID has been set.
  static const int none = -1;

  bool hasUnknownCriticalOption = false;

  /// The type of this CoAP message.
  int type = CoapMessageType.unknown;

  /// The code of this CoAP message.
  int code = CoapCode.notSet;

  /// The codestring
  String get codeString => CoapCode.codeToString(code);

  int? _id;

  /// The ID of this CoAP message.
  int? get id => _id;
  @protected
  set id(int? val) => _id = val;

  final Map<OptionType, List<CoapOption>> _optionMap = {};
  CoapEventBus? _eventBus = CoapEventBus(namespace: '');

  /// Option map
  Map<OptionType, List<CoapOption>> get optionMap => _optionMap;

  /// Host name to resolve
  String resolveHost = 'localhost';

  /// Bind address if not using the default
  InternetAddress? bindAddress;

  @protected
  void setEventBus(CoapEventBus eventBus) {
    _eventBus = eventBus;
  }

  CoapEventBus? get eventBus => _eventBus;

  String? get namespace => _eventBus?.namespace;

  /// Adds an option to the list of options of this CoAP message.
  CoapMessage addOption(CoapOption option) {
    if (!_optionMap.containsKey(option.type)) {
      _optionMap[option.type] = <CoapOption>[];
    }
    _optionMap[option.type]!.add(option);
    return this;
  }

  /// Remove a specific option, returns true if the option has been removed.
  bool removeOption(CoapOption option) {
    var ret = false;
    final options = getOptions(option.type) as List<CoapOption>?;
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
  bool removeOptions(OptionType optionType) {
    _optionMap.remove(optionType);
    return true;
  }

  /// Gets all options of the given type.
  Iterable<CoapOption>? getOptions(OptionType optionType) =>
      _optionMap[optionType];

  /// Gets a list of all options.
  Iterable<CoapOption> getAllOptions() {
    final list = <CoapOption>[];
    for (final Iterable<CoapOption> opts in _optionMap.values) {
      if (opts.isNotEmpty) {
        list.addAll(opts);
      }
    }
    return list;
  }

  /// Sets an option, removing all others of the option type
  void setOption(CoapOption opt) {
    removeOptions(opt.type);
    addOption(opt);
  }

  /// Sets all options with the specified option type, removing
  /// all others of the same type.
  void setOptions(Iterable<CoapOption> options) {
    for (final opt in options) {
      removeOptions(opt.type);
    }
    addOptions(options);
  }

  /// Returns the first option of the specified type, or null
  CoapOption? getFirstOption(OptionType optionType) {
    return getOptions(optionType)
        ?.toList()
        .firstWhereOrNull((element) => element.type == optionType);
  }

  /// Clear all options
  void clearOptions() => _optionMap.clear();

  /// Checks if this CoAP message has options of the specified option type.
  /// Returns true if options of the specified type exists.
  bool hasOption(OptionType type) => getFirstOption(type) != null;

  typed.Uint8Buffer? _token;

  /// The 0-8 byte token.
  typed.Uint8Buffer? get token => _token;

  /// As a string
  String get tokenString =>
      _token != null ? CoapByteArrayUtil.toHexString(_token!) : '';

  set token(typed.Uint8Buffer? value) {
    if (value != null && value.length > 8) {
      throw ArgumentError.value(value, 'Message::token',
          'Token length must be between 0 and 8 inclusive.');
    }
    _token = value;
  }

  /// Gets a value that indicates whether this CoAP message is a
  /// request message.
  bool get isRequest => CoapCode.isRequest(code);

  /// Gets a value that indicates whether this CoAP message is a
  /// response message.
  bool get isResponse => CoapCode.isResponse(code);

  /// Gets a value that indicates whether this CoAP message is
  /// an empty message.
  bool get isEmpty => CoapCode.isEmpty(code);

  /// Gets a value that indicates whether this CoAP message is a
  /// valid message.
  bool get isValid => CoapCode.isValid(code);

  /// The destination endpoint.
  @protected
  CoapInternetAddress? destination;

  /// The source endpoint.
  @protected
  CoapInternetAddress? source;

  /// Acknowledged hook for attaching a callback if needed
  HookFunction? acknowledgedHook;

  bool _acknowledged = false;

  /// Indicates whether this message has been acknowledged.
  bool get isAcknowledged => _acknowledged;
  @protected
  set isAcknowledged(bool value) {
    _acknowledged = value;
    _eventBus?.fire(CoapAcknowledgedEvent(this));
    acknowledgedHook?.call();
  }

  bool _rejected = false;

  /// Indicates whether this message has been rejected.
  bool get isRejected => _rejected;
  @protected
  set isRejected(bool value) {
    _rejected = value;
    _eventBus?.fire(CoapRejectedEvent(this));
  }

  /// Timed out hook function for attaching a callback if needed
  HookFunction? timedOutHook;

  bool _timedOut = false;

  /// Indicates whether this message has been timed out.
  bool get isTimedOut => _timedOut;
  @protected
  set isTimedOut(bool value) {
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
  @protected
  set isCancelled(bool value) {
    _cancelled = value;
    _eventBus?.fire(CoapCancelledEvent(this));
  }

  bool _duplicate = false;

  /// Indicates whether this message is a duplicate.
  bool get duplicate => _duplicate;
  @protected
  set duplicate(bool val) => _duplicate = val;

  typed.Uint8Buffer? _bytes;

  /// The serialized message as byte array, or null if not serialized yet.
  typed.Uint8Buffer? get bytes => _bytes;
  @protected
  set bytes(typed.Uint8Buffer? val) => _bytes = val;

  DateTime? _timestamp;

  /// The timestamp when this message has been received or sent,
  /// or null if neither has happened yet.
  DateTime? get timestamp => _timestamp;
  @protected
  set timestamp(DateTime? val) => _timestamp = val;

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
  final convertor.Utf8Decoder _utfDecoder = const convertor.Utf8Decoder();
  final convertor.Utf8Encoder _utfEncoder = const convertor.Utf8Encoder();

  /// The payload of this CoAP message.
  typed.Uint8Buffer? payload;

  /// The size of the payload of this CoAP message.
  int get payloadSize => payload?.length ?? 0;

  /// The payload of this CoAP message in string representation.
  String? get payloadString {
    if (payload != null && payload!.isNotEmpty) {
      try {
        final ret = _utfDecoder.convert(payload!);
        return ret;
      } on FormatException {
        // The payload may be incomplete, if so and the conversion
        // fails indicate this.
        return '<<<< Payload incomplete >>>>>';
      }
    }
    return null;
  }

  /// Sets the payload from a string with a default media type
  set payloadString(String? value) =>
      setPayloadMedia(value, CoapMediaType.textPlain);

  /// Sets the payload.
  CoapMessage setPayload(String payload) {
    this.payload ??= typed.Uint8Buffer();
    this.payload!.addAll(_utfEncoder.convert(payload));
    return this;
  }

  /// Sets the payload and media type of this CoAP message.
  CoapMessage setPayloadMedia(String? payload, int mediaType) {
    if (payload == null) {
      return this;
    }
    this.payload ??= typed.Uint8Buffer();
    this.payload!.addAll(_utfEncoder.convert(payload));
    contentType = mediaType;
    return this;
  }

  /// Sets the payload of this CoAP message.
  CoapMessage setPayloadMediaRaw(typed.Uint8Buffer payload, int mediaType) {
    this.payload = payload;
    contentType = mediaType;
    return this;
  }

  /// Select options helper
  List<CoapOption> _selectOptions(OptionType optionType) {
    final ret = <CoapOption>[];
    final opts = getOptions(optionType);
    if (opts != null) {
      opts.forEach(ret.add);
    }
    return ret;
  }

  /// If-Matches.
  List<CoapOption> get ifMatches => _selectOptions(OptionType.ifMatch).toList();

  /// Add an if match option, if a null string is passed the if match is not set
  CoapMessage addIfMatch(String etag) =>
      addOption(CoapOption.createString(OptionType.ifMatch, etag));

  /// Add an opaque if match
  CoapMessage addIfMatchOpaque(typed.Uint8Buffer opaque) {
    if (opaque.length > 8) {
      throw ArgumentError.value(opaque.length, 'Message::addIfMatch',
          'Content of If-Match option is too large');
    }
    return addOption(CoapOption.createRaw(OptionType.ifMatch, opaque));
  }

  /// Remove an opaque if match
  CoapMessage removeIfMatchOpaque(typed.Uint8Buffer opaque) {
    final opts = _optionMap[OptionType.ifMatch];
    opts?.removeWhere((CoapOption o) => o.byteValue.equals(opaque));
    if (opts != null && opts.isEmpty) {
      _optionMap.remove(OptionType.ifMatch);
    }
    return this;
  }

  /// Remove an if match option
  CoapMessage removeIfMatch(CoapOption option) {
    if (option.type != OptionType.ifMatch) {
      throw ArgumentError.value(
          option.type, 'Message::removeIfMatch', 'Not an if match option');
    }
    removeOption(option);
    return this;
  }

  /// Clear the if matches
  CoapMessage clearIfMatches() {
    removeOptions(OptionType.ifMatch);
    return this;
  }

  /// Etags
  Iterable<CoapOption> get etags => _selectOptions(OptionType.eTag).toList();

  /// Contains an opaque E-tag
  bool containsETagOpaque(typed.Uint8Buffer opaque) =>
      getOptions(OptionType.eTag)
          ?.firstWhereOrNull((CoapOption o) => o.byteValue.equals(opaque)) !=
      null;

  /// Add an opaque ETag
  CoapMessage addETagOpaque(typed.Uint8Buffer opaque) {
    return addOption(CoapOption.createRaw(OptionType.eTag, opaque));
  }

  /// Adds an ETag option
  CoapMessage addEtag(CoapOption option) {
    if (option.type != OptionType.eTag) {
      throw ArgumentError.notNull('Message::addETag, option is not an etag');
    }
    return addOption(option);
  }

  /// Remove an ETag, true indicates success
  bool removeEtag(CoapOption option) {
    if (option.type != OptionType.eTag) {
      throw ArgumentError.notNull('Message::removeETag, option is not an etag');
    }
    return removeOption(option);
  }

  /// Remove an opaque ETag
  CoapMessage removeETagOpaque(typed.Uint8Buffer opaque) {
    final opts = _optionMap[OptionType.eTag];
    opts?.removeWhere((CoapOption o) => o.byteValue.equals(opaque));
    if (opts != null && opts.isEmpty) {
      _optionMap.remove(OptionType.eTag);
    }
    return this;
  }

  /// Clear the E tags
  CoapMessage clearETags() {
    removeOptions(OptionType.eTag);
    return this;
  }

  /// If-None Matches.
  Iterable<CoapOption> get ifNoneMatches =>
      _selectOptions(OptionType.ifNoneMatch).toList();

  /// Add an if none match option
  CoapMessage addIfNoneMatch(CoapOption option) {
    if (option.type != OptionType.ifNoneMatch) {
      throw ArgumentError.value(
          'Message::addIfNoneMatch', 'Option is not an if none match');
    }
    return addOption(option);
  }

  /// Add an opaque if none match
  CoapMessage addIfNoneMatchOpaque(typed.Uint8Buffer? opaque) {
    if (opaque == null) {
      throw ArgumentError.notNull('Message::addIfNoneMatch');
    }
    if (opaque.length > 8) {
      throw ArgumentError.value(opaque.length, 'Message::addIfNoneMatch',
          'Content of If-None Match option is too large');
    }
    return addOption(CoapOption.createRaw(OptionType.ifNoneMatch, opaque));
  }

  /// Remove an opaque if none match
  CoapMessage removeIfNoneMatchOpaque(typed.Uint8Buffer opaque) {
    final opts = _optionMap[OptionType.ifNoneMatch];
    opts?.removeWhere((CoapOption o) => o.byteValue.equals(opaque));
    if (opts != null && opts.isEmpty) {
      _optionMap.remove(OptionType.ifNoneMatch);
    }
    return this;
  }

  /// Remove an if none match option
  CoapMessage removeIfNoneMatch(CoapOption option) {
    if (option.type != OptionType.ifNoneMatch) {
      throw ArgumentError.value(option.type, 'Message::removeIfNoneMatch',
          'Not an if none match option');
    }
    removeOption(option);
    return this;
  }

  /// Clear the if none matches
  CoapMessage clearIfNoneMatches() {
    removeOptions(OptionType.ifNoneMatch);
    return this;
  }

  /// Uri's
  String? get uriHost {
    final host = getFirstOption(OptionType.uriHost);
    return host?.toString();
  }

  @protected
  set uriHost(String? value) {
    if (value == null) {
      throw ArgumentError.notNull('Message::uriHost');
    }
    if (value.isEmpty || value.length > 255) {
      throw ArgumentError.value(value.length, 'Message::uriHost',
          'URI-Host option\'s length must be between 1 and 255 inclusive');
    }
    setOption(CoapOption.createString(OptionType.uriHost, value));
  }

  /// URI path
  String get uriPath {
    final join = CoapOption.join(
        getOptions(OptionType.uriPath) as List<CoapOption>?, '/')!;
    return join + '/';
  }

  /// Sets a number of Uri path options from a string, ignores any trailing / character
  set uriPath(String value) {
    var out = value;
    if (out.endsWith('/')) {
      out = out.substring(0, out.length - 1);
    }
    setOptions(CoapOption.split(OptionType.uriPath, out, '/'));
  }

  /// URI paths
  Iterable<CoapOption> get uriPaths =>
      _selectOptions(OptionType.uriPath).toList();

  /// URI paths as a string with no trailing '/'
  String get uriPathsString {
    final sb = StringBuffer();
    for (final option in uriPaths) {
      sb.write(option.stringValue);
      if (option != uriPaths.last) {
        sb.write('/');
      }
    }
    return sb.toString();
  }

  /// Add a URI path
  CoapMessage addUriPath(String? path) {
    if (path == null) {
      throw ArgumentError.notNull('Message::addUriPath');
    }
    if (path.length > 255) {
      throw ArgumentError.value(path.length, 'Message::addUriPath',
          'Uri Path option\'s length must be between 0 and 255 inclusive');
    }
    return addOption(CoapOption.createString(OptionType.uriPath, path));
  }

  /// Remove a URI path
  CoapMessage removeUriPath(String path) {
    final opts = _optionMap[OptionType.uriPath];
    opts?.removeWhere((CoapOption o) => o.stringValue == path);
    if (opts != null && opts.isEmpty) {
      _optionMap.remove(OptionType.uriPath);
    }
    return this;
  }

  /// Clear URI paths
  CoapMessage clearUriPath() {
    _optionMap.remove(OptionType.uriPath);
    return this;
  }

  /// URI query
  String get uriQuery => CoapOption.join(
      getOptions(OptionType.uriQuery) as List<CoapOption>?, '&')!;

  /// Set a URI query
  set uriQuery(String value) {
    var tmp = value;
    if (value.isNotEmpty && value.startsWith('?')) {
      tmp = value.substring(1);
    }
    setOptions(CoapOption.split(OptionType.uriQuery, tmp, '&'));
  }

  /// URI queries
  Iterable<CoapOption> get uriQueries =>
      _selectOptions(OptionType.uriQuery).toList();

  /// URI queries as a string with no trailing '/'
  String get uriQueriesString {
    final sb = StringBuffer();
    for (final option in uriQueries) {
      sb.write(option.stringValue);
      if (option != uriQueries.last) {
        sb.write('&');
      }
    }
    return '?${sb.toString()}';
  }

  /// Add a URI query
  CoapMessage addUriQuery(String? query) {
    if (query == null) {
      throw ArgumentError.notNull('Message::addUriQuery');
    }
    if (query.length > 255) {
      throw ArgumentError.value(query.length, 'Message::addUriQuery',
          'Uri Query option\'s length must be between 0 and 255 inclusive');
    }
    return addOption(CoapOption.createUriQuery(query));
  }

  /// Remove a URI query
  CoapMessage removeUriQuery(String query) {
    final opts = _optionMap[OptionType.uriQuery];
    opts?.removeWhere((CoapOption o) => o.stringValue == query);
    if (opts != null && opts.isEmpty) {
      _optionMap.remove(OptionType.uriQuery);
    }
    return this;
  }

  /// Clear URI queries
  CoapMessage clearUriQuery() {
    removeOptions(OptionType.uriQuery);
    return this;
  }

  /// Uri port
  int get uriPort {
    final opt = getFirstOption(OptionType.uriPort);
    return opt?.value ?? 0;
  }

  set uriPort(int value) {
    if (value == 0) {
      removeOptions(OptionType.uriPort);
    } else {
      setOption(CoapOption.createVal(OptionType.uriPort, value));
    }
  }

  /// Location path as a string
  String get locationPathsString {
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
  set locationPath(String value) {
    // Check for '..' or '.' are invalid values
    if (value.contains('..') || value.contains('.')) {
      throw ArgumentError.value('Message::locationPath');
    }
    var out = value;
    if (out.endsWith('/')) {
      out = out.substring(0, out.length - 1);
    }
    setOptions(CoapOption.split(OptionType.locationPath, out, '/'));
  }

  /// Location paths
  Iterable<CoapOption> get locationPaths =>
      _selectOptions(OptionType.locationPath);

  /// Location
  String get location {
    var path = '/$locationPathsString';
    final query = locationQuery;
    if (query.isNotEmpty) {
      path += '?$query';
    }
    return path;
  }

  /// Add a location path
  CoapMessage addLocationPath(String? path) {
    if (path == null) {
      throw ArgumentError.notNull('Message::addLocationPath');
    }
    if (path.length > 255) {
      throw ArgumentError.value(path.length, 'Message::addLocationPath',
          'Location Path option\'s length must be between 0 and 255 inclusive');
    }
    return addOption(CoapOption.createString(OptionType.locationPath, path));
  }

  /// Remove a location path
  CoapMessage removelocationPath(String path) {
    final opts = _optionMap[OptionType.locationPath];
    opts?.removeWhere((CoapOption o) => o.stringValue == path);
    if (opts != null && opts.isEmpty) {
      _optionMap.remove(OptionType.locationPath);
    }
    return this;
  }

  /// Clear location path
  CoapMessage clearLocationPath() {
    _optionMap.remove(OptionType.locationPath);
    return this;
  }

  /// Location query
  String get locationQuery => CoapOption.join(
      getOptions(OptionType.locationQuery) as List<CoapOption>?, '&')!;

  /// Set a location query
  set locationQuery(String value) {
    var tmp = value;
    if (value.isNotEmpty && value.startsWith('?')) {
      tmp = value.substring(1);
    }
    setOptions(CoapOption.split(OptionType.locationQuery, tmp, '&'));
  }

  /// Location queries
  Iterable<CoapOption> get locationQueries =>
      _selectOptions(OptionType.locationQuery).toList();

  /// Location queries as a string with no trailing '/'
  String get locationQueriesString {
    final sb = StringBuffer();
    for (final option in locationQueries) {
      sb.write(option.stringValue);
      if (option != locationQueries.last) {
        sb.write('&');
      }
    }
    return '?${sb.toString()}';
  }

  /// Add a location query
  CoapMessage addLocationQuery(String? query) {
    if (query == null) {
      throw ArgumentError.notNull('Message::addLocationQuery');
    }
    if (query.length > 255) {
      throw ArgumentError.value(
          query.length,
          'Message::addLocationQuery',
          'Location Query option\'s length must be between '
              '0 and 255 inclusive');
    }
    return addOption(CoapOption.createString(OptionType.locationQuery, query));
  }

  /// Remove a location query
  CoapMessage removeLocationQuery(String query) {
    final opts = _optionMap[OptionType.locationQuery];
    opts?.removeWhere((CoapOption o) => o.stringValue == query);
    if (opts != null && opts.isEmpty) {
      _optionMap.remove(OptionType.locationQuery);
    }
    return this;
  }

  /// Clear location  queries
  CoapMessage clearLocationQuery() {
    removeOptions(OptionType.locationQuery);
    return this;
  }

  /// Content type
  int get contentType {
    final opt = getFirstOption(OptionType.contentFormat);
    return opt?.value ?? CoapMediaType.undefined;
  }

  set contentType(int value) {
    if (value == CoapMediaType.undefined) {
      removeOptions(OptionType.contentFormat);
    } else {
      setOption(CoapOption.createVal(OptionType.contentFormat, value));
    }
  }

  /// The content-format of this CoAP message,
  /// Same as ContentType, only another name.
  int get contentFormat => contentType;

  set contentFormat(int value) => contentType = value;

  /// The max-age of this CoAP message.
  int get maxAge {
    final opt = getFirstOption(OptionType.maxAge);
    return opt?.value ?? CoapConstants.defaultMaxAge;
  }

  set maxAge(int value) {
    if (value < 0 || value > 4294967295) {
      throw ArgumentError.value(
          value,
          'Message::maxAge',
          'Max-Age option must be between 0 and 4294967295 '
              '(4 bytes) inclusive');
    }
    setOption(CoapOption.createVal(OptionType.maxAge, value));
  }

  /// Accept
  int get accept {
    final opt = getFirstOption(OptionType.accept);
    return opt?.value ?? CoapMediaType.undefined;
  }

  set accept(int value) {
    if (value == CoapMediaType.undefined) {
      removeOptions(OptionType.accept);
    } else {
      setOption(CoapOption.createVal(OptionType.accept, value));
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

  set proxyUri(Uri? value) {
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

  set proxyScheme(String? value) {
    if (value == null) {
      removeOptions(OptionType.proxyScheme);
    } else {
      setOption(CoapOption.createString(OptionType.proxyScheme, value));
    }
  }

  /// Observe
  int? get observe {
    final opt = getFirstOption(OptionType.observe);
    return opt?.value;
  }

  @protected
  set observe(int? value) {
    if (value == null) {
      removeOptions(OptionType.observe);
    } else if (value < 0 || ((1 << 24) - 1) < value) {
      throw ArgumentError.value(
          value,
          'Message::observe',
          'Observe option must be between 0 and '
              '${(1 << 24) - 1} (3 bytes) inclusive');
    } else {
      setOption(CoapOption.createVal(OptionType.observe, value));
    }
  }

  /// Size 1
  int get size1 {
    final opt = getFirstOption(OptionType.size1);
    return opt?.value ?? 0;
  }

  set size1(int? value) {
    if (value == null) {
      removeOptions(OptionType.size1);
    } else {
      setOption(CoapOption.createVal(OptionType.size1, value));
    }
  }

  /// Size 2
  int? get size2 {
    final opt = getFirstOption(OptionType.size2);
    return opt?.value ?? 0;
  }

  set size2(int? value) {
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
  set block1(CoapBlockOption? value) {
    if (value == null) {
      removeOptions(OptionType.block1);
    } else {
      setOption(value);
    }
  }

  /// Block 1
  void setBlock1(int szx, int num, {required bool m}) {
    setOption(CoapBlockOption.fromParts(OptionType.block1, num, szx, m: m));
  }

  /// Block 2
  CoapBlockOption? get block2 =>
      getFirstOption(OptionType.block2) as CoapBlockOption?;

  set block2(CoapBlockOption? value) {
    if (value == null) {
      removeOptions(OptionType.block2);
    } else {
      setOption(value);
    }
  }

  /// Block 2
  void setBlock2(int szx, int num, {required bool m}) {
    setOption(CoapBlockOption.fromParts(OptionType.block2, num, szx, m: m));
  }

  /// Copy an event handler
  void copyEventHandler(CoapMessage msg) {
    acknowledgedHook = msg.acknowledgedHook;
    retransmittingHook = msg.retransmittingHook;
    timedOutHook = msg.timedOutHook;
  }

  @override
  String toString() => '\nType: ${type.toString()}, Code: $codeString, '
      'Id: ${id.toString()}, '
      'Token: \'$tokenString\',\n'
      'Options: ${_optionsToString()},\n'
      'Payload: $payloadString';

  String _optionsToString() {
    final sb = StringBuffer();
    sb.writeln('[');
    sb.write(_optionString('If-Match', ifMatches));
    sb.write(_optionString('Uri Host', uriHost));
    sb.write(_optionString('E-tags', etags));
    sb.write(_optionString('If-None Match', ifNoneMatches));
    sb.write(_optionString('Uri Port', uriPort > 0 ? uriPort : null));
    sb.write(_optionString('Location Paths', locationPaths));
    sb.write(_optionString('Uri Paths', uriPathsString));
    sb.write(_optionString('Content-Type', CoapMediaType.name(contentType)));
    sb.write(_optionString('Max Age', maxAge));
    sb.write(_optionString('Uri Queries', uriQueries));
    if (accept != CoapMediaType.undefined) {
      sb.write(_optionString('Accept', CoapMediaType.name(accept)));
    }
    sb.write(_optionString('Location Queries', locationQueries));
    sb.write(_optionString('Proxy Uri', proxyUri));
    sb.write(_optionString('Proxy Scheme', proxyScheme));
    sb.write(_optionString('Block 1', block1));
    sb.write(_optionString('Block 2', block2));
    sb.write(_optionString('Observe', observe));
    sb.write(_optionString('Size 1', size1));
    sb.write(_optionString('Size 2', size2));
    sb.write(']');
    return sb.toString();
  }

  String _optionString(String name, Object? value) {
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
}
