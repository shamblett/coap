/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/05/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Event classes
class CoapAcknowledgedEvent {}

class CoapRejectedEvent {}

class CoapTimedOutEvent {}

class CoapCancelledEvent {}

/// The class Message models the base class of all CoAP messages.
/// CoAP messages are of type Request, Response or EmptyMessage,
/// each of which has a MessageType, a message identifier,
/// a token (0-8 bytes), a collection of Options and a payload.
class CoapMessage extends Object with events.EventEmitter {
  /// Instantiates a message with the given type.
  CoapMessage(this.type);

  /// Instantiates a message with the given type and code.
  CoapMessage.withCode(this.type, this.code);

  /// Indicates that no ID has been set.
  static const int none = -1;

  /// Invalid message ID.
  static const int invalidID = none;

  /// The type of this CoAP message.
  int type = CoapMessageType.unknown;

  /// The code of this CoAP message.
  int code;

  String get codeString => CoapCode.codeToString(code);

  /// The ID of this CoAP message.
  int id = none;

  /// Option map
  Map<int, List<CoapOption>> _optionMap = new Map<int, List<CoapOption>>();

  Map<int, List<CoapOption>> get optionMap => _optionMap;

  /// Adds an option to the list of options of this CoAP message.
  CoapMessage addOption(CoapOption option) {
    if (option == null) {
      throw new ArgumentError.notNull("Message::addOption - option is null");
    }
    if (option.type == optionTypeToken) {
      // be compatible with draft 13-
      token = option.valueBytes;
      return this;
    }
    if (!_optionMap.containsKey(option.type)) {
      _optionMap[option.type] = new List<CoapOption>();
    }
    _optionMap[option.type].add(option);
    return this;
  }

  /// Adds all option to the list of options of this CoAP message.
  void addOptions(Iterable<CoapOption> options) {
    for (CoapOption opt in options) {
      addOption(opt);
    }
  }

  /// Removes all options of the given type from this CoAP message.
  bool removeOptions(int optionType) {
    _optionMap.remove(optionType);
    return true;
  }

  /// Gets all options of the given type.
  Iterable<CoapOption> getOptions(int optionType) {
    return optionMap.containsKey(optionType) ? optionMap[optionType] : null;
  }

  /// Gets a list of all options.
  Iterable<CoapOption> getSortedOptions() {
    final List<CoapOption> list = new List<CoapOption>();
    for (Iterable<CoapOption> opts in _optionMap.values) {
      if (opts.length > 0) list.addAll(opts);
    }
    return list;
  }

  /// Sets an option.
  void setOption(CoapOption opt) {
    if (opt != null) {
      removeOptions(opt.type);
      addOption(opt);
    }
  }

  /// Sets all options with the specified option type.
  void setOptions(Iterable<CoapOption> options) {
    if (options == null) return;
    for (CoapOption opt in options) {
      removeOptions(opt.type);
    }
    addOptions(options);
  }

  /// Gets the first option of the specified option type.
  /// Returns the first option of the specified type, or null
  CoapOption getFirstOption(int optionType) {
    final List<CoapOption> list = getOptions(optionType);
    if (list == null) {
      return null;
    }
    return list.length > 0 ? list.first : null;
  }

  /// Checks if this CoAP message has options of the specified option type.
  /// Returns true if options of the specified type exists.
  bool hasOption(int type) {
    return getFirstOption(type) != null;
  }

  /// The 0-8 byte token.
  typed.Uint8Buffer _token;

  typed.Uint8Buffer get token => _token;

  String get tokenString => CoapByteArrayUtil.toHexString(_token);

  set token(typed.Uint8Buffer value) {
    if (value != null && value.length > 8) {
      throw new ArgumentError.value(value, "Message::token",
          "Token length must be between 0 and 8 inclusive.");
    }
    _token = value;
  }

  /// Gets a value that indicates whether this CoAP message is a request message.
  bool get isRequest => CoapCode.isRequest(code);

  /// Gets a value that indicates whether this CoAP message is a response message.
  bool get isResponse => CoapCode.isResponse(code);

  /// The destination endpoint.
  InternetAddress destination;

  /// The source endpoint.
  InternetAddress source;

  /// Indicates whether this message has been acknowledged.
  bool _acknowledged;

  bool get isAcknowledged => _acknowledged;

  set isAcknowledged(bool value) {
    _acknowledged = value;
    emitEvent(new CoapAcknowledgedEvent());
  }

  /// Indicates whether this message has been rejected.
  bool _rejected;

  bool get isRejected => _rejected;

  set isRejected(bool value) {
    _rejected = value;
    emitEvent(new CoapRejectedEvent());
  }

  /// Indicates whether this message has been timed out.
  bool _timedOut;

  bool get isTimedOut => _timedOut;

  set isTimedOut(bool value) {
    _timedOut = value;
    emitEvent(new CoapTimedOutEvent());
  }

  /// Indicates whether this message has been cancelled.
  bool _cancelled;

  bool get isCancelled => _cancelled;

  set isCancelled(bool value) {
    _cancelled = value;
    emitEvent(new CoapCancelledEvent());
  }

  /// Indicates whether this message is a duplicate.
  bool duplicate;

  /// The serialized message as byte array, or null if not serialized yet.
  typed.Uint8Buffer bytes;

  /// The timestamp when this message has been received or sent,
  /// or null if neither has happened yet.
  DateTime timestamp;

  /// The max times this message should be retransmitted if no ACK received.
  /// A value of 0 means that the CoapConstants.maxRetransmit time
  /// shoud be taken into account, while a negative means NO retransmission.
  /// The default value is 0.
  int maxRetransmit;

  /// the amount of time in milliseconds after which this message will time out.
  /// A value of 0 indicates that the time should be decided automatically,
  /// while a negative that never time out. The default value is 0.
  int ackTimeout;

  /// UTF8 decoder and encoder helpers
  final convertor.Utf8Decoder _utfDecoder = new convertor.Utf8Decoder();
  final convertor.Utf8Encoder _utfEncoder = new convertor.Utf8Encoder();

  /// The payload of this CoAP message.
  typed.Uint8Buffer _payload;

  typed.Uint8Buffer get payload => _payload;

  set payload(typed.Uint8Buffer value) {
    _payload = value;
  }

  /// The size of the payload of this CoAP message.
  int get payloadSize => null == _payload ? 0 : _payload.length;

  /// The payload of this CoAP message in string representation.
  String get payloadString => _utfDecoder.convert(_payload);

  set payloadString(String value) =>
      setPayloadMedia(value, CoapMediaType.textPlain);

  /// Sets the payload of this CoAP message.
  CoapMessage setPayload(String payload) {
    if (payload == null) {
      return this;
    }
    if (_payload == null) {
      _payload = new typed.Uint8Buffer();
    }
    _payload.addAll(_utfEncoder.convert(payload));
    return this;
  }

  /// Sets the payload of this CoAP message.
  CoapMessage setPayloadMedia(String payload, int mediaType) {
    if (payload == null) {
      return this;
    }
    if (_payload == null) {
      _payload = new typed.Uint8Buffer();
    }
    _payload.addAll(_utfEncoder.convert(payload));
    contentType = mediaType;
    return this;
  }

  /// Sets the payload of this CoAP message.
  CoapMessage setPayloadMediaRaw(typed.Uint8Buffer payload, int mediaType) {
    _payload = payload;
    contentType = mediaType;
    return this;
  }

  /// Cancels this message.
  void cancel() {
    isCancelled = true;
  }

  /// To string.
  String toString() {
    String payload = payloadString;
    if (payload == null) {
      payload = "[no payload]";
    } else {
      final int len = payloadSize;
      final int nl = payload.indexOf('\n');
      if (nl >= 0) payload = payload.substring(0, nl);
      if (len > 24) payload = payload.substring(0, 24);
      payload = "\"" + payload + "\"";
      if (payload.length != len + 2)
        payload += "... " + payloadSize.toString() + " bytes";
    }
    return "${type.toString()}-${codeString} ID=${id
        .toString()}, Token=${tokenString}, Options=[${CoapUtil.optionsToString(
        this)}], ${payload}";
  }

  /// Equals.
  bool operator ==(Object obj) {
    if (obj == null) {
      return false;
    }
    if (identical(this, obj)) {
      return true;
    }
    if ((obj is CoapMessage) && (type != obj.type)) {
      return false;
    }
    if ((obj is CoapMessage) && (code != obj.code)) {
      return false;
    }
    if ((obj is CoapMessage) && (id != obj.id)) {
      return false;
    }
    if (optionMap == null) {
      if ((obj is CoapMessage) && (obj.optionMap != null)) return false;
    } else if ((obj is CoapMessage) && (optionMap != obj.optionMap)) {
      return false;
    }
    CoapMessage other;
    if (obj is CoapMessage) {
      other = obj;
    }
    if (!CoapUtil.areSequenceEqualTo(payload, other.payload)) {
      return false;
    }
    return true;
  }

  /// Hash code.
  int get hashCode => super.hashCode;

  /// Select options helper
  Iterable _selectOptions(int optionType, func(CoapOption option)) sync* {
    final Iterable<CoapOption> opts = getOptions(optionType);
    if (opts != null) {
      for (CoapOption opt in opts) {
        yield func(opt);
      }
    }
  }

  /// If-Matches.
  typed.Uint8Buffer get ifMatches =>
      _selectOptions(optionTypeIfMatch, (CoapOption o) => o.valueBytes);

  bool isIfMatch(typed.Uint8Buffer what) {
    if (CoapUtil.areSequenceEqualTo(what, ifMatches)) {
      return true;
    }
    return false;
  }

  CoapMessage addIfMatch(typed.Uint8Buffer opaque) {
    if (opaque == null) {
      throw new ArgumentError.notNull("Message::addIfMatch");
    }
    if (opaque.length > 8) {
      throw new ArgumentError.value(opaque.length, "Message::addIfMatch",
          "Content of If-Match option is too large");
    }
    return addOption(CoapOption.createRaw(optionTypeIfMatch, opaque));
  }

  CoapMessage removeIfMatch(typed.Uint8Buffer opaque) {
    final List<CoapOption> list = getOptions(optionTypeIfMatch);
    if (list != null) {
      final CoapOption opt = CoapUtil.firstOrDefault(list,
              (CoapOption o) =>
              CoapUtil.areSequenceEqualTo(opaque, o.valueBytes));
      if (opt != null) list.remove(opt);
    }
    return this;
  }

  CoapMessage clearIfMatches() {
    removeOptions(optionTypeIfMatch);
    return this;
  }

  /// Etags
  typed.Uint8Buffer get etags =>
      _selectOptions(optionTypeETag, (CoapOption o) => o.valueBytes);

  bool containsETag(typed.Uint8Buffer what) =>
      CoapUtil.contains(
          getOptions(optionTypeETag),
              (CoapOption o) =>
              CoapUtil.areSequenceEqualTo(what, o.valueBytes));

  CoapMessage addETag(typed.Uint8Buffer opaque) {
    if (opaque == null) {
      throw new ArgumentError.notNull("Message::addETag");
    }
    return addOption(CoapOption.createRaw(optionTypeETag, opaque));
  }

  CoapMessage removeETag(typed.Uint8Buffer opaque) {
    final List<CoapOption> list = getOptions(optionTypeETag);
    if (list != null) {
      final CoapOption opt = CoapUtil.firstOrDefault(list,
              (CoapOption o) =>
              CoapUtil.areSequenceEqualTo(opaque, o.valueBytes));
      if (opt != null) {
        list.remove(opt);
      }
    }
    return this;
  }

  CoapMessage clearETags() {
    removeOptions(optionTypeETag);
    return this;
  }

  /// IfNoneMatch
  bool get ifNoneMatch => hasOption(optionTypeIfNoneMatch);

  set ifNonematch(int value) {
    if (value != null) {
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
      throw new ArgumentError.notNull("Message::uriHost");
    }
    if (value.length < 1 || value.length > 255) {
      throw new ArgumentError.value(value.length, "Message::uriHost",
          "URI-Host option's length must be between 1 and 255 inclusive");
    }
    setOption(CoapOption.createString(optionTypeUriHost, value));
  }

  String get uriPath =>
      "/" + CoapOption.join(getOptions(optionTypeUriPath), "/");

  set uriPath(String value) =>
      setOptions(CoapOption.split(optionTypeUriPath, value, "/"));

  Iterable<String> get uriPaths sync* {
    final Iterable<CoapOption> opts = getOptions(optionTypeUriPath);
    if (opts != null) {
      for (CoapOption opt in opts) {
        yield opt.toString();
      }
    }
  }

  CoapMessage addUriPath(String path) {
    if (path == null) {
      throw new ArgumentError.notNull("Message::addUriPath");
    }
    if (path.length > 255) {
      throw new ArgumentError.value(path.length, "Message::addUriPath",
          "Uri Path option's length must be between 0 and 255 inclusive");
    }
    return addOption(CoapOption.createString(optionTypeUriPath, path));
  }

  CoapMessage removeUriPath(String path) {
    final List<CoapOption> list = getOptions(optionTypeUriPath);
    if (list != null) {
      final CoapOption opt =
      CoapUtil.firstOrDefault(list, (CoapOption o) => path == o.toString());
      if (opt != null) list.remove(opt);
    }
    return this;
  }

  CoapMessage clearUriPath() {
    removeOptions(optionTypeUriPath);
    return this;
  }

  String get uriQuery => CoapOption.join(getOptions(optionTypeUriQuery), "&");

  set uriQuery(String value) {
    String tmp = value;
    if (value.isNotEmpty && value.startsWith("?")) {
      tmp = value.substring(1);
    }
    setOptions(CoapOption.split(optionTypeUriQuery, tmp, "&"));
  }

  Iterable<String> get uriQueries sync* {
    final Iterable<CoapOption> opts = getOptions(optionTypeUriQuery);
    if (opts != null) {
      for (CoapOption opt in opts) {
        yield opt.toString();
      }
    }
  }

  CoapMessage addUriQuery(String query) {
    if (query == null) {
      throw new ArgumentError.notNull("Message::addUriQuery");
    }
    if (query.length > 255) {
      throw new ArgumentError.value(query.length, "Message::addUriQuery",
          "Uri Query option's length must be between 0 and 255 inclusive");
    }
    return addOption(CoapOption.createString(optionTypeUriQuery, query));
  }

  CoapMessage removeUriQuery(String query) {
    final List<CoapOption> list = getOptions(optionTypeUriQuery);
    if (list != null) {
      final CoapOption opt = CoapUtil.firstOrDefault(
          list, (CoapOption o) => query == o.toString());
      if (opt != null) list.remove(opt);
    }
    return this;
  }

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
    if (value == 0)
      removeOptions(optionTypeUriPort);
    else
      setOption(CoapOption.createVal(optionTypeUriPort, value));
  }

  /// Location
  String get locationPath =>
      CoapOption.join(getOptions(optionTypeLocationPath), "/");

  set locationPath(String value) =>
      setOptions(CoapOption.split(optionTypeLocationPath, value, "/"));

  Iterable<String> get locationPaths =>
      _selectOptions(optionTypeLocationPath, (CoapOption o) => o.toString());

  String get location {
    String path = "/" + locationPath;
    final String query = locationQuery;
    if (query.isNotEmpty) {
      path += "?" + query;
    }
    return path;
  }

  CoapMessage addLocationPath(String path) {
    if (path == null) {
      throw new ArgumentError.notNull("Message::addLocationPath");
    }
    if (path.length > 255) {
      throw new ArgumentError.value(path.length, "Message::addLocationPath",
          "Location Path option's length must be between 0 and 255 inclusive");
    }
    return addOption(CoapOption.createString(optionTypeLocationPath, path));
  }

  CoapMessage removelocationPath(String path) {
    final List<CoapOption> list = getOptions(optionTypeLocationPath);
    if (list != null) {
      final CoapOption opt =
      CoapUtil.firstOrDefault(list, (CoapOption o) => path == o.toString());
      if (opt != null) list.remove(opt);
    }
    return this;
  }

  CoapMessage clearLocationPath() {
    removeOptions(optionTypeLocationPath);
    return this;
  }

  String get locationQuery =>
      CoapOption.join(getOptions(optionTypeLocationQuery), "&");

  set locationQuery(String value) {
    String tmp = value;
    if (value.isNotEmpty && value.startsWith("?")) {
      tmp = value.substring(1);
    }
    setOptions(CoapOption.split(optionTypeLocationQuery, tmp, "&"));
  }

  Iterable<String> get locationQueries =>
      _selectOptions(optionTypeLocationQuery, (CoapOption o) => o.toString());

  CoapMessage addLocationQuery(String query) {
    if (query == null) {
      throw new ArgumentError.notNull("Message::addLocationQuery");
    }
    if (query.length > 255) {
      throw new ArgumentError.value(query.length, "Message::addLocationQuery",
          "Location Query option's length must be between 0 and 255 inclusive");
    }
    return addOption(CoapOption.createString(optionTypeLocationQuery, query));
  }

  CoapMessage removeLocationQuery(String query) {
    final List<CoapOption> list = getOptions(optionTypeLocationQuery);
    if (list != null) {
      final CoapOption opt = CoapUtil.firstOrDefault(
          list, (CoapOption o) => query == o.toString());
      if (opt != null) list.remove(opt);
    }
    return this;
  }

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
      throw new ArgumentError.value(value, "Message::maxAge",
          "Max-Age option must be between 0 and 4294967295 (4 bytes) inclusive");
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
    if (!proxyUriString.startsWith("coap://") &&
        !proxyUriString.startsWith("coaps://") &&
        !proxyUriString.startsWith("http://") &&
        !proxyUriString.startsWith("https://")) {
      proxyUriString = "coap://" + proxyUriString;
    }
    return new Uri.dataFromString(proxyUriString);
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
      return null;
    } else {
      return opt.value;
    }
  }

  set observe(int value) {
    if (value == null) {
      removeOptions(optionTypeObserve);
    } else if (value < 0 || ((1 << 24) - 1) < value) {
      throw new ArgumentError.value(
          value,
          "Message::observe",
          "Observe option must be between 0 and ${((1 << 24) -
              1)} (3 bytes) inclusive");
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
  CoapBlockOption get block1 =>
      getFirstOption(optionTypeBlock1) as CoapBlockOption;

  set block1(CoapBlockOption value) {
    if (value == null) {
      removeOptions(optionTypeBlock1);
    } else {
      setOption(value);
    }
  }

  void setBlock1(int szx, bool m, int num) {
    setOption(new CoapBlockOption.fromParts(optionTypeBlock1, num, szx, m));
  }

  /// Block 2
  CoapBlockOption get block2 =>
      getFirstOption(optionTypeBlock2) as CoapBlockOption;

  set block2(CoapBlockOption value) {
    if (value == null) {
      removeOptions(optionTypeBlock2);
    } else {
      setOption(value);
    }
  }

  void setBlock2(int szx, bool m, int num) {
    setOption(new CoapBlockOption.fromParts(optionTypeBlock2, num, szx, m));
  }
}
