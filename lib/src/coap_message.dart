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
import 'codec/tcp/message_encoder.dart';
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

  bool hasUnknownCriticalOption = false;

  bool hasFormatError = false;

  CoapMessageType _type;

  @internal
  set type(final CoapMessageType type) => _type = type;

  /// The type of this CoAP message.
  CoapMessageType get type => _type;

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

  /// Indicates if this message needs to be rejected as specified in
  /// [RFC 7252, section 5.4.1].
  ///
  /// [RFC 7252, section 5.4.1]: https://www.rfc-editor.org/rfc/rfc7252#section-5.4.1
  bool get needsRejection =>
      (type == CoapMessageType.non && hasUnknownCriticalOption) ||
      hasFormatError ||
      (this is CoapResponse && hasUnknownCriticalOption);

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
  bool get isActive => !isTimedOut && !isCancelled && !isRejected;

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

  /// The payload of this CoAP message.
  final Uint8Buffer payload;

  /// The size of the payload of this CoAP message.
  int get payloadSize => payload.length;

  /// The payload of this CoAP message in string representation.
  String get payloadString {
    final payload = this.payload;
    if (payload.isNotEmpty) {
      try {
        final ret = utf8.decode(payload);
        return ret;
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
  List<ETagOption> get etags => getOptions<ETagOption>();

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
  List<IfNoneMatchOption> get ifNoneMatches => getOptions<IfNoneMatchOption>();

  /// Remove an if none match option
  void removeIfNoneMatch(final IfNoneMatchOption option) {
    removeOption(option);
  }

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
  int? get maxAge {
    final opt = getFirstOption<MaxAgeOption>();
    return opt?.value;
  }

  set maxAge(final int? value) {
    if (value == null) {
      removeOptions<MaxAgeOption>();
    } else {
      setOption(MaxAgeOption(value));
    }
  }

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
  int? get size1 {
    final opt = getFirstOption<Size1Option>();
    return opt?.value;
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
    return opt?.value;
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
  }) =>
      deserializeUdpMessage(
        data,
        scheme,
        destinationAddress: destinationAddress,
      );

  /// Serializes this CoAP message into the UDP message format.
  ///
  /// Is also used for DTLS.
  Uint8Buffer toUdpPayload() => serializeUdpMessage(this);

  /// Serializes this CoAP message into the TCP message format.
  ///
  /// Is also used for TLS.
  Uint8Buffer toTcpPayload() => serializeTcpMessage(this);
}
