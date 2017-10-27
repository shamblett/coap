/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/05/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Event classes
class AcknowledgedEvent {}

class RejectedEvent {}

class TimedOutEvent {}

class CancelledEvent {}

/// The class Message models the base class of all CoAP messages.
/// CoAP messages are of type Request, Response or EmptyMessage,
/// each of which has a MessageType, a message identifier,
/// a token (0-8 bytes), a collection of Options and a payload.
class Message extends Object with events.EventEmitter {
  /// Indicates that no ID has been set.
  static const int none = -1;

  /// Invalid message ID.
  static const int invalidID = none;

  /// The type of this CoAP message.
  int type = MessageType.unknown;

  /// The code of this CoAP message.
  int code;

  String get codeString => Code.codeToString(code);

  /// The ID of this CoAP message.
  int id = none;

  /// Option map
  Map<int, List<Option>> _optionMap = new Map<int, List<Option>>();

  Map<int, List<Option>> get optionMap => _optionMap;

  /// Adds an option to the list of options of this CoAP message.
  Message addOption(Option option) {
    if (option == null) {
      throw new ArgumentError.notNull("Message::addOption - option is null");
    }
    if (option.type == optionTypeToken) {
      // be compatible with draft 13-
      token = option.valueBytes;
      return this;
    }
    _optionMap[option.type] = new List<Option>();
    return this;
  }

  /// Adds all option to the list of options of this CoAP message.
  void addOptions(Iterable<Option> options) {
    for (Option opt in options) {
      addOption(opt);
    }
  }

  /// Removes all options of the given type from this CoAP message.
  bool removeOptions(int optionType) {
    _optionMap.remove(optionType);
    return true;
  }

  /// Gets all options of the given type.
  Iterable<Option> getOptions(int optionType) {
    return optionMap.containsKey(optionType) ? optionMap[optionType] : null;
  }

  /// Gets a list of all options.
  Iterable<Option> getSortedOptions() {
    final List<Option> list = new List<Option>();
    for (Iterable<Option> opts in _optionMap.values) {
      if (opts.length > 0) list.addAll(opts);
    }
    return list;
  }

  /// Sets an option.
  void setOption(Option opt) {
    if (opt != null) {
      removeOptions(opt.type);
      addOption(opt);
    }
  }

  /// Sets all options with the specified option type.
  void setOptions(Iterable<Option> options) {
    if (options == null) return;
    for (Option opt in options) {
      removeOptions(opt.type);
    }
    addOptions(options);
  }

  /// Gets the first option of the specified option type.
  /// Returns the first option of the specified type, or null
  Option getFirstOption(int optionType) {
    final List<Option> list = getOptions(optionType);
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
  String get tokenString => _token.toString();
  set token(typed.Uint8Buffer value) {
    if (value != null && value.length > 8) {
      throw new ArgumentError.value(value, "Message::token",
          "Token length must be between 0 and 8 inclusive.");
    }
    _token = value;
  }

  /// Gets a value that indicates whether this CoAP message is a request message.
  bool get isRequest => Code.isRequest(code);

  /// Gets a value that indicates whether this CoAP message is a response message.
  bool get isResponse => Code.isResponse(code);

  /// The destination endpoint.
  InternetAddress destination;

  /// The source endpoint.
  InternetAddress source;

  /// Indicates whether this message has been acknowledged.
  bool _acknowledged;

  bool get isAcknowledged => _acknowledged;

  set isAcknowledged(bool value) {
    _acknowledged = value;
    emitEvent(new AcknowledgedEvent());
  }

  /// Indicates whether this message has been rejected.
  bool _rejected;

  bool get isRejected => _rejected;

  set isRejected(bool value) {
    _rejected = value;
    emitEvent(new RejectedEvent());
  }

  /// Indicates whether this message has been timed out.
  bool _timedOut;

  bool get isTimedOut => _timedOut;

  set isTimedOut(bool value) {
    _timedOut = value;
    emitEvent(new TimedOutEvent());
  }

  /// Indicates whether this message has been cancelled.
  bool _cancelled;

  bool get isCancelled => _cancelled;

  set isCancelled(bool value) {
    _cancelled = value;
    emitEvent(new CancelledEvent());
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
      setPayloadMedia(value, MediaType.textPlain);

  /// Sets the payload of this CoAP message.
  Message setPayload(String payload) {
    String temp = payload;
    if (payload == null) temp = "";
    _payload = _utfEncoder.convert(temp);
    return this;
  }

  /// Sets the payload of this CoAP message.
  Message setPayloadMedia(String payload, int mediaType) {
    String temp = payload;
    if (payload == null) temp = "";
    _payload = _utfEncoder.convert(temp);
    MessContentType = mediaType;
    return this;
  }

  /// Sets the payload of this CoAP message.
  Message setPayloadMedia(typed.Uint8Buffer payload, int mediaType) {
    _payload = payload;
    MessContentType = mediaType;
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
        .toString()}, Token=${tokenString}, Options=[${Util.optionsToString(
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
    if ((obj is Message) && (type != obj.type)) {
      return false;
    }
    if ((obj is Message) && (code != obj.code)) {
      return false;
    }
    if ((obj is Message) && (id != obj.id)) {
      return false;
    }
    if (optionMap == null) {
      if ((obj is Message) && (obj.optionMap != null)) return false;
    } else if ((obj is Message) && (optionMap != obj.optionMap)) {
      return false;
    }
    Message other;
    if (obj is Message) {
      other = obj;
    }
    if (!Util.areSequenceEqualTo(payload, other.payload)) {
      return false;
    }
    return true;
  }

  /// Hash code.
  int get hashCode => super.hashCode;

  /// Select options helper
  Iterable _selectOptions(int optionType, func(Option option)) sync* {
    final Iterable<Option> opts = getOptions(optionType);
    if (opts != null) {
      for (Option opt in opts) {
        yield func(opt);
      }
    }
  }

  /// If-Matches.
  typed.Uint8Buffer get ifMatches =>
      _selectOptions(optionTypeIfMatch, (Option o) => o.valueBytes);
  bool isIfMatch(typed.Uint8Buffer what) {
    if (Util.areSequenceEqualTo(what, ifMatches)) {
      return true;
    }
    return false;
  }

  Message addIfMatch(typed.Uint8Buffer opaque) {
    if (opaque == null) {
      throw new ArgumentError.notNull("Message::addIfMatch");
    }
    if (opaque.length > 8) {
      throw new ArgumentError.value(opaque.length, "Message::addIfMatch",
          "Content of If-Match option is too large");
    }
    return addOption(Option.createRaw(optionTypeIfMatch, opaque));
  }

  Message removeIfMatch(typed.Uint8Buffer opaque) {
    final List<Option> list = getOptions(optionTypeIfMatch);
    if (list != null) {
      final Option opt = Util.firstOrDefault(
          list, (Option o) => Util.areSequenceEqualTo(opaque, o.valueBytes));
      if (opt != null) list.remove(opt);
    }
    return this;
  }

  Message clearIfMatches() {
    removeOptions(optionTypeIfMatch);
    return this;
  }

  /// Etags
  typed.Uint8Buffer get etags =>
      _selectOptions(optionTypeETag, (Option o) => o.valueBytes);

  bool containsETag(typed.Uint8Buffer what) =>
      Util.contains(
          getOptions(optionTypeETag),
              (Option o) => Util.areSequenceEqualTo(what, o.valueBytes));

  Message addETag(typed.Uint8Buffer opaque) {
    if (opaque == null) {
      throw new ArgumentError.notNull("Message::addETag");
    }
    return addOption(Option.createRaw(optionTypeETag, opaque));
  }

  Message removeETag(typed.Uint8Buffer opaque) {
    final List<Option> list = getOptions(optionTypeETag);
    if (list != null) {
      final Option opt = Util.firstOrDefault(
          list, (Option o) => Util.areSequenceEqualTo(opaque, o.valueBytes));
      if (opt != null) {
        list.remove(opt);
      }
    }
    return this;
  }

  Message clearETags() {
    removeOptions(optionTypeETag);
    return this;
  }

  /// IfNoneMatch
  bool get ifNoneMatch => hasOption(optionTypeIfNoneMatch);

  set ifNonematch(int value) {
    if (value != null) {
      Option.create(optionTypeIfNoneMatch);
    } else {
      removeOptions(optionTypeIfNoneMatch);
    }
  }

  /// Uri's
  String get uriHost {
    final Option host = getFirstOption(optionTypeUriHost);
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
    setOption(Option.createString(optionTypeUriHost, value));
  }

  String get uriPath => "/" + Option.join(getOptions(optionTypeUriPath), "/");

  set uriPath(String value) =>
      setOptions(Option.split(optionTypeUriPath, value, "/"));

  Iterable<String> get uriPaths sync* {
    final Iterable<Option> opts = getOptions(optionTypeUriPath);
    if (opts != null) {
      for (Option opt in opts) {
        yield opt.toString();
      }
    }
  }

  Message addUriPath(String path) {
    if (path == null) {
      throw new ArgumentError.notNull("Message::addUriPath");
    }
    if (path.length > 255) {
      throw new ArgumentError.value(path.length, "Message::addUriPath",
          "Uri Path option's length must be between 0 and 255 inclusive");
    }
    return addOption(Option.createString(optionTypeUriPath, path));
  }

  Message removeUriPath(String path) {
    final List<Option> list = getOptions(optionTypeUriPath);
    if (list != null) {
      final Option opt =
      Util.firstOrDefault(list, (Option o) => path == o.toString());
      if (opt != null) list.remove(opt);
    }
    return this;
  }

  Message clearUriPath() {
    removeOptions(optionTypeUriPath);
    return this;
  }

  String get uriQuery => Option.join(getOptions(optionTypeUriQuery), "&");

  set uriQuery(String value) {
    String tmp = value;
    if (value.isNotEmpty && value.startsWith("?")) {
      tmp = value.substring(1);
    }
    setOptions(Option.split(optionTypeUriQuery, tmp, "&"));
  }

  Iterable<String> get uriQueries sync* {
    final Iterable<Option> opts = getOptions(optionTypeUriQuery);
    if (opts != null) {
      for (Option opt in opts) {
        yield opt.toString();
      }
    }
  }

  Message addUriQuery(String query) {
    if (query == null) {
      throw new ArgumentError.notNull("Message::addUriQuery");
    }
    if (query.length > 255) {
      throw new ArgumentError.value(query.length, "Message::addUriQuery",
          "Uri Query option's length must be between 0 and 255 inclusive");
    }
    return addOption(Option.createString(optionTypeUriQuery, query));
  }

  Message removeUriQuery(String query) {
    final List<Option> list = getOptions(optionTypeUriQuery);
    if (list != null) {
      final Option opt =
      Util.firstOrDefault(list, (Option o) => query == o.toString());
      if (opt != null) list.remove(opt);
    }
    return this;
  }

  Message clearUriQuery() {
    removeOptions(optionTypeUriQuery);
    return this;
  }

  /// Uri port
  int get uriPort {
    final Option opt = getFirstOption(optionTypeUriPort);
    return opt == null ? null : opt.value;
  }

  /// Location
  String get locationPath =>
      Option.join(getOptions(optionTypeLocationPath), "/");

  set locationPath(String value) =>
      setOptions(Option.split(optionTypeLocationPath, value, "/"));

  Iterable<String> get locationPaths =>
      _selectOptions(optionTypeLocationPath, (Option o) => o.toString());

  String get location {
    String path = "/" + locationPath;
    final String query = locationQuery;
    if (query.isNotEmpty) {
      path += "?" + query;
    }
    return path;
  }

  Message addLocationPath(String path) {
    if (path == null) {
      throw new ArgumentError.notNull("Message::addLocationPath");
    }
    if (path.length > 255) {
      throw new ArgumentError.value(path.length, "Message::addLocationPath",
          "Location Path option's length must be between 0 and 255 inclusive");
    }
    return addOption(Option.createString(optionTypeLocationPath, path));
  }

  Message removelocationPath(String path) {
    final List<Option> list = getOptions(optionTypeLocationPath);
    if (list != null) {
      final Option opt =
      Util.firstOrDefault(list, (Option o) => path == o.toString());
      if (opt != null) list.remove(opt);
    }
    return this;
  }

  Message clearLocationPath() {
    removeOptions(optionTypeLocationPath);
    return this;
  }

  String get locationQuery =>
      Option.join(getOptions(optionTypeLocationQuery), "&");

  set locationQuery(String value) {
    String tmp = value;
    if (value.isNotEmpty && value.startsWith("?")) {
      tmp = value.substring(1);
    }
    setOptions(Option.split(optionTypeLocationQuery, tmp, "&"));
  }

  Iterable<String> get locationQueries =>
      _selectOptions(optionTypeLocationQuery, (Option o) => o.toString());

  Message addLocationQuery(String query) {
    if (query == null) {
      throw new ArgumentError.notNull("Message::addLocationQuery");
    }
    if (query.length > 255) {
      throw new ArgumentError.value(query.length, "Message::addLocationQuery",
          "Location Query option's length must be between 0 and 255 inclusive");
    }
    return addOption(Option.createString(optionTypeLocationQuery, query));
  }

  Message removeLocationQuery(String query) {
    final List<Option> list = getOptions(optionTypeLocationQuery);
    if (list != null) {
      final Option opt =
      Util.firstOrDefault(list, (Option o) => query == o.toString());
      if (opt != null) list.remove(opt);
    }
    return this;
  }

  Message clearLocationQuery() {
    removeOptions(optionTypeLocationQuery);
    return this;
  }

/// Content type

}
