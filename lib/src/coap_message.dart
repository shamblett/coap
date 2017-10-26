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

  /// Gets or sets the 0-8 byte token.
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

  /// Gets all options of the given type.
  Iterable<Option> getOptions(int optionType) {
    return optionMap.containsKey(optionType) ? optionMap[optionType] : null;
  }

  /// Select options helper
  Iterable _selectOptions(int optionType, func(Option option)) sync* {
    final Iterable<Option> opts = getOptions(optionType);
    if (opts != null) {
      for (Option opt in opts) {
        yield func(opt);
      }
    }
  }

  /// Gets If-Match options.
  typed.Uint8Buffer get ifMatches =>
      _selectOptions(optionTypeIfMatch, (Option o) => o.valueBytes);

  bool isIfMatch(typed.Uint8Buffer what) {
    if (Util.areSequenceEqualTo(what, ifMatches)) {
      return true;
    }
    return false;
  }
}
