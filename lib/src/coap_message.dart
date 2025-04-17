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
  bool hasUnknownCriticalOption = false;

  bool hasFormatError = false;

  /// The code of this CoAP message.
  final CoapCode code;

  /// Bind address if not using the default
  InternetAddress? bindAddress;

  /// The destination endpoint.
  @internal
  InternetAddress? destination;

  /// The source endpoint.
  @internal
  InternetAddress? source;

  /// Timed out hook function for attaching a callback if needed
  HookFunction? timedOutHook;

  /// Acknowledged hook for attaching a callback if needed
  HookFunction? acknowledgedHook;

  /// Retransmit hook function
  HookFunction? retransmittingHook;

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

  /// The payload of this CoAP message.
  final Uint8Buffer payload;

  CoapMessageType _type;

  int? _id;

  CoapEventBus? _eventBus = CoapEventBus(namespace: '');

  final List<Option<Object?>> _options = [];

  Uint8Buffer? _token;

  bool _acknowledged = false;

  bool _rejected = false;

  bool _timedOut = false;

  int _retransmits = 0;

  bool _cancelled = false;

  bool _duplicate = false;

  DateTime? _timestamp;

  /// The type of this CoAP message.
  CoapMessageType get type => _type;

  /// The codestring
  String get codeString => code.toString();

  /// The ID of this CoAP message.
  int? get id => _id;

  int get optionsLength => _options.length;

  CoapEventBus? get eventBus => _eventBus;

  String? get namespace => _eventBus?.namespace;

  /// Indicates if this message needs to be rejected as specified in
  /// [RFC 7252, section 5.4.1].
  ///
  /// [RFC 7252, section 5.4.1]: https://www.rfc-editor.org/rfc/rfc7252#section-5.4.1
  bool get needsRejection =>
      (type == CoapMessageType.non && hasUnknownCriticalOption) ||
      hasFormatError ||
      (this is CoapResponse && hasUnknownCriticalOption);

  /// The 0-8 byte token.
  Uint8Buffer? get token => _token;

  /// As a string
  String get tokenString {
    final token = _token;
    return token != null ? CoapByteArrayUtil.toHexString(token) : '';
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

  /// Indicates whether this message has been acknowledged.
  bool get isAcknowledged => _acknowledged;

  /// Indicates whether this message has been rejected.
  bool get isRejected => _rejected;

  /// Indicates whether this message has been timed out.
  bool get isTimedOut => _timedOut;

  /// Returns `true` if this [CoapMessage] has neither timed out nor has been
  /// canceled.
  bool get isActive => !isTimedOut && !isCancelled && !isRejected;

  /// The current number of retransmits
  int get retransmits => _retransmits;

  /// Indicates whether this message has been cancelled.
  bool get isCancelled => _cancelled;

  /// Indicates whether this message is a duplicate.
  bool get duplicate => _duplicate;

  /// The timestamp when this message has been received or sent,
  /// or null if neither has happened yet.
  DateTime? get timestamp => _timestamp;

  /// The size of the payload of this CoAP message.
  int get payloadSize => payload.length;

  /// Etags
  List<ETagOption> get etags => getOptions<ETagOption>();

  /// The payload of this CoAP message in string representation.
  String get payloadString {
    final payload = this.payload;
    if (payload.isNotEmpty) {
      try {
        return utf8.decode(payload);
      } on FormatException catch (_) {
        // The payload may be incomplete, if so and the conversion
        // fails indicate this.
        return '<<<< Payload incomplete >>>>>';
      }
    }
    return '';
  }

  /// If-Matches.
  List<IfMatchOption> get ifMatches => getOptions<IfMatchOption>();

  /// If-None Matches.
  List<IfNoneMatchOption> get ifNoneMatches => getOptions<IfNoneMatchOption>();

  /// Content type
  CoapMediaType? get contentType {
    final opt = getFirstOption<ContentFormatOption>();
    if (opt == null) {
      return null;
    }

    return CoapMediaType.fromIntValue(opt.value);
  }

  /// The content-format of this CoAP message,
  /// Same as ContentType, only another name.
  CoapMediaType? get contentFormat => contentType;

  /// The max-age of this CoAP message.
  int? get maxAge {
    final opt = getFirstOption<MaxAgeOption>();
    return opt?.value;
  }

  /// Accept
  CoapMediaType? get accept {
    final opt = getFirstOption<AcceptOption>();
    if (opt == null) {
      return null;
    }

    return CoapMediaType.fromIntValue(opt.value);
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

  /// Proxy scheme
  String? get proxyScheme {
    final opt = getFirstOption<ProxySchemeOption>();
    return opt?.toString();
  }

  /// Observe
  int? get observe => getFirstOption<ObserveOption>()?.value;

  /// Size 1
  int? get size1 {
    final opt = getFirstOption<Size1Option>();
    return opt?.value;
  }

  /// Size 2
  int? get size2 {
    final opt = getFirstOption<Size2Option>();
    return opt?.value;
  }

  /// Block 1
  CoapBlockOption? get block1 => getFirstOption<Block1Option>();

  /// Block 2
  CoapBlockOption? get block2 => getFirstOption<Block2Option>();

  String? get _formattedOptions {
    final options = getAllOptions();

    if (options.isEmpty) {
      return null;
    }

    const indent = '\n  ';
    const optionDelimiter = ',$indent';

    final formattedOptions = options
        .groupListsBy((final option) => option.type)
        .values
        .map(
          (final optionList) => optionList
              .map((final option) => option.toString())
              .join(optionDelimiter),
        )
        .join(optionDelimiter);

    return 'Options: [$indent$formattedOptions\n]';
  }

  set proxyScheme(final String? value) {
    if (value == null) {
      removeOptions<ProxySchemeOption>();
    } else {
      setOption(ProxySchemeOption(value));
    }
  }

  /// Block 1
  set block1(final CoapBlockOption? value) {
    if (value == null) {
      removeOptions<Block1Option>();
    } else {
      setOption(value);
    }
  }

  @internal
  set type(final CoapMessageType type) => _type = type;

  @internal
  set id(final int? val) => _id = val;

  @internal
  set eventBus(final CoapEventBus? eventBus) => _eventBus = eventBus;

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

  @internal
  set isAcknowledged(final bool value) {
    _acknowledged = value;
    _eventBus?.fire(CoapAcknowledgedEvent(this));
    acknowledgedHook?.call();
  }

  @internal
  set isRejected(final bool value) {
    _rejected = value;
    _eventBus?.fire(CoapRejectedEvent(this));
  }

  @internal
  set isTimedOut(final bool value) {
    _timedOut = value;
    _eventBus?.fire(CoapTimedOutEvent(this));
    timedOutHook?.call();
  }

  @internal
  set isCancelled(final bool value) {
    _cancelled = value;
    _eventBus?.fire(CoapCancelledEvent(this));
  }

  @internal
  set duplicate(final bool val) => _duplicate = val;

  set contentType(final CoapMediaType? value) {
    if (value == null) {
      removeOptions<ContentFormatOption>();
    } else {
      setOption(ContentFormatOption(value.numericValue));
    }
  }

  set contentFormat(final CoapMediaType? value) => contentType = value;

  @internal
  set timestamp(final DateTime? val) => _timestamp = val;

  set maxAge(final int? value) {
    if (value == null) {
      removeOptions<MaxAgeOption>();
    } else {
      setOption(MaxAgeOption(value));
    }
  }

  set accept(final CoapMediaType? value) {
    if (value == null) {
      removeOptions<AcceptOption>();
    } else {
      setOption(AcceptOption(value.numericValue));
    }
  }

  set proxyUri(final Uri? value) {
    if (value == null) {
      removeOptions<ProxyUriOption>();
    } else {
      setOption(ProxyUriOption(value.toString()));
    }
  }

  @internal
  set observe(final int? value) {
    if (value == null) {
      removeOptions<ObserveOption>();
    } else {
      setOption(ObserveOption(value));
    }
  }

  set size1(final int? value) {
    if (value == null) {
      removeOptions<Size1Option>();
    } else {
      setOption(Size1Option(value));
    }
  }

  set size2(final int? value) {
    if (value == null) {
      removeOptions<Size2Option>();
    } else {
      setOption(Size2Option(value));
    }
  }

  set block2(final CoapBlockOption? value) {
    if (value == null) {
      removeOptions<Block2Option>();
    } else {
      setOption(value);
    }
  }

  CoapMessage(
    this.code,
    this._type, {
    final Iterable<int>? payload,
    final CoapMediaType? contentFormat,
  }) : payload = Uint8Buffer()..addAll(payload ?? []) {
    contentType = contentFormat;
  }

  CoapMessage.fromParsed(
    this.code,
    this._type, {
    required final int id,
    required final Uint8Buffer token,
    required final List<Option<Object?>> options,
    required final Uint8Buffer? payload,
    required this.hasUnknownCriticalOption,
    required this.hasFormatError,
  }) : payload = payload ?? Uint8Buffer() {
    this.id = id;
    this.token = token;
    setOptions(options);
  }

  /// Adds an option to the list of options of this [CoapMessage].
  void addOption(final Option<Object?> option) {
    if (!option.repeatable) {
      _options.removeWhere((final element) => element.type == option.type);
    }
    _options.add(option);
  }

  /// Remove a specific option, returns true if the option has been removed.
  bool removeOption(final Option<Object?> option) => _options.remove(option);

  /// Removes all options for which the given [test] function returns `true`.
  void removeOptionWhere(final bool Function(Option<Object?>) test) =>
      _options.removeWhere(test);

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

  /// Fire retransmitting event
  void fireRetransmitting() {
    _retransmits++;
    _eventBus?.fire(CoapRetransmitEvent(this));
    retransmittingHook?.call();
  }

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

  /// Remove an if none match option
  void removeIfNoneMatch(final IfNoneMatchOption option) {
    removeOption(option);
  }

  /// Block 1
  void setBlock1(final BlockSize szx, final int num, {required final bool m}) {
    setOption(Block1Option.fromParts(num, szx, m: m));
  }

  /// Block 2
  void setBlock2(final BlockSize szx, final int num, {required final bool m}) {
    setOption(Block2Option.fromParts(num, szx, m: m));
  }

  /// Copy an event handler
  void copyEventHandler(final CoapMessage msg) {
    acknowledgedHook = msg.acknowledgedHook;
    retransmittingHook = msg.retransmittingHook;
    timedOutHook = msg.timedOutHook;
  }

  @override
  String toString() {
    final elements = ['Type: $type', 'Id: $id'];

    if (token != null) {
      elements.add('Token: $tokenString');
    }

    final formattedOptions = _formattedOptions;
    if (formattedOptions != null) {
      elements.add(formattedOptions);
    }

    elements.add('Payload: $payloadString');

    return '\n${elements.join(',\n')}\n';
  }

  /// Generates a new CoAP message from [data] in the UDP message format.
  ///
  /// The [scheme] can contain the value `coap` or `coaps` and will be used
  /// in the `uri` field of CoAP request objects.
  ///
  /// The [destinationAddress] might be used when setting the URI for an
  /// incoming CoAP request that does not contain an Uri-Host option.
  static CoapMessage? fromUdpPayload(
    final Uint8Buffer data,
    final String scheme, {
    final InternetAddress? destinationAddress,
  }) => deserializeUdpMessage(
    data,
    scheme,
    destinationAddress: destinationAddress,
  );

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
  Uint8Buffer toTcpPayload() =>
      throw UnimplementedError(
        'TCP segment serialization is not implemented yet.',
      );
}
