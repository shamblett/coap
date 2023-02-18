// SPDX-FileCopyrightText: © 2023 Jan Romann <jan.romann@uni-bremen.de>

// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:typed_data/typed_data.dart';

import '../../coap_code.dart';
import '../../coap_empty_message.dart';
import '../../coap_message.dart';
import '../../coap_request.dart';
import '../../coap_response.dart';
import '../../option/coap_option_type.dart';
import '../../option/option.dart';
import '../../option/uri_converters.dart';
import '../udp/datagram_reader.dart';
import '../udp/message_format.dart' as message_format;

enum TcpState {
  initialState,
  extendedLength,
  extendedTokenLength,
  code,
  token,
  optionsAndPayload,
}

final toByteStream =
    StreamTransformer<Uint8List, int>((final input, final cancelOnError) {
  final controller = StreamController<int>();

  controller.onListen = () {
    final subscription = input.listen(
      (final bytes) => bytes.forEach(controller.add),
      onDone: controller.close,
      onError: controller.addError,
      cancelOnError: cancelOnError,
    );
    controller
      ..onPause = subscription.pause
      ..onResume = subscription.resume
      ..onCancel = subscription.cancel;
  };

  return controller.stream.listen(null);
});

class RawCoapTcpMessage {
  RawCoapTcpMessage({
    required this.code,
    required this.optionsAndPayload,
    required this.token,
  });

  final int code;

  final Uint8List optionsAndPayload;

  final Uint8List token;

  @override
  String toString() =>
      'Code: $code\nToken:$token\nOptions and Payload:$optionsAndPayload';
}

final toRawCoapTcpStream = StreamTransformer<int, RawCoapTcpMessage>(
    (final input, final cancelOnError) {
  // TODO(JKRhb): Connections must be aborted on error
  final controller = StreamController<RawCoapTcpMessage>();

  var state = TcpState.initialState;
  var length = 0;
  var extendedLengthBytes = 0;
  final extendedLengthBuffer = Uint8Buffer();
  var tokenLength = 0;
  final token = Uint8Buffer();
  var extendedTokenLengthBytes = 0;
  final extendedTokenLengthBuffer = Uint8Buffer();
  var code = 0;
  final optionsAndPayload = Uint8Buffer();

  controller.onListen = () {
    final subscription = input.listen(
      (final byte) async {
        switch (state) {
          case TcpState.initialState:
            token.clear();
            extendedLengthBuffer.clear();
            optionsAndPayload.clear();
            extendedTokenLengthBuffer.clear();

            // TODO(JKRhb): Handle WebSockets case with length = 0
            length = (byte >> 4) & 15;
            tokenLength = byte & 15;

            if (const [13, 14, 15].contains(length)) {
              state = TcpState.extendedLength;
              extendedLengthBytes = determineExtendedLength(length);
              break;
            }

            state = TcpState.code;
            break;
          case TcpState.extendedLength:
            extendedLengthBuffer.add(byte);
            if (extendedLengthBytes-- <= 0) {
              length = _readExtendedMessageLength(
                length,
                DatagramReader(extendedLengthBuffer),
              );
              state = TcpState.code;
              break;
            }

            break;
          case TcpState.code:
            code = byte;
            if (const [13, 14].contains(tokenLength)) {
              state = TcpState.extendedTokenLength;
              extendedTokenLengthBytes = determineExtendedLength(length);
              break;
            } else if (tokenLength == 15) {
              throw const FormatException();
            }
            state = TcpState.token;
            break;
          case TcpState.extendedTokenLength:
            extendedTokenLengthBuffer.add(byte);
            extendedTokenLengthBytes--;

            if (extendedTokenLengthBytes < 1) {
              length = _readExtendedMessageLength(
                length,
                DatagramReader(extendedLengthBuffer),
              );

              state = TcpState.code;
              break;
            }

            break;
          case TcpState.token:
            token.add(byte);
            tokenLength--;

            if (tokenLength >= 1) {
              break;
            }

            // TODO(JKRhb): Refactor
            if (length < 1) {
              state = TcpState.initialState;
              controller.add(
                RawCoapTcpMessage(
                  code: code,
                  token: Uint8List.fromList(token.toList(growable: false)),
                  optionsAndPayload: Uint8List.fromList(
                    optionsAndPayload.toList(growable: false),
                  ),
                ),
              );
            } else {
              state = TcpState.optionsAndPayload;
            }

            break;
          case TcpState.optionsAndPayload:
            optionsAndPayload.add(byte);
            length--;

            if (length < 1) {
              state = TcpState.initialState;
              controller.add(
                RawCoapTcpMessage(
                  code: code,
                  token: Uint8List.fromList(token.toList(growable: false)),
                  optionsAndPayload: Uint8List.fromList(
                    optionsAndPayload.toList(growable: false),
                  ),
                ),
              );
            }

            break;
        }
      },
      onDone: controller.close,
      onError: controller.addError,
      cancelOnError: cancelOnError,
    );
    controller
      ..onPause = subscription.pause
      ..onResume = subscription.resume
      ..onCancel = subscription.cancel;
  };

  return controller.stream.listen(null);
});

int determineExtendedLength(final int length) {
  switch (length) {
    case 13:
      return 1;
    case 14:
      return 2;
    case 15:
      return 4;
  }

  throw const FormatException('message');
}

/// Transforms a [Stream] of [RawCoapTcpMessage]s into [CoapMessage]s.
///
/// Returns the deserialized message, or `null` if the message can not be
/// decoded, i.e. the bytes do not represent a [CoapRequest], a [CoapResponse]
/// or a [CoapEmptyMessage].
final deserializeTcpMessage = StreamTransformer<RawCoapTcpMessage, CoapMessage>(
    (final input, final cancelOnError) {
  final controller = StreamController<CoapMessage>();

  controller.onListen = () {
    final subscription = input.listen(
      (final coapTcpMessage) {
        final code = CoapCode.decode(coapTcpMessage.code);

        if (code == null) {
          throw const FormatException('Encountered unknown CoapCode');
        }

        final token = coapTcpMessage.token;

        final reader = DatagramReader(
          Uint8Buffer()..addAll(coapTcpMessage.optionsAndPayload),
        );

        try {
          final options = readOptions(reader);
          final payload = reader.readBytesLeft();
          final tokenBuffer = Uint8Buffer()..addAll(token);
          final CoapMessage coapMessage;

          // TODO(JKRhb): Probably not really needed for TCP, since connections
          //              are simply closed on error
          const hasUnknownCriticalOption = false;
          const hasFormatError = false;

          if (code.isRequest) {
            final method = RequestMethod.fromCoapCode(code);
            if (method == null) {
              return;
            }

            final uri = optionsToUri(
              options.where((final option) => option.isUriOption).toList(),
              scheme: 'coap+tcp', // TODO(JKRhb): Replace
              destinationAddress:
                  InternetAddress('127.0.0.1'), // TODO(JKRhb): Replace
            );

            coapMessage = CoapRequest.fromParsed(
              uri,
              method,
              token: tokenBuffer,
              options: options,
              payload: payload,
              hasUnknownCriticalOption: hasUnknownCriticalOption,
              hasFormatError: hasFormatError,
            );
          } else if (code.isResponse) {
            final responseCode = ResponseCode.fromCoapCode(code);
            if (responseCode == null) {
              return;
            }

            final location = optionsToUri(
              options.where((final option) => option.isLocationOption).toList(),
            );

            coapMessage = CoapResponse.fromParsed(
              responseCode,
              token: tokenBuffer,
              options: options,
              payload: payload,
              location: location,
              hasUnknownCriticalOption: hasUnknownCriticalOption,
              hasFormatError: hasFormatError,
            );
          } else if (code.isEmpty) {
            coapMessage = CoapEmptyMessage.fromParsed(
              token: tokenBuffer,
              options: options,
              payload: payload,
              hasUnknownCriticalOption: hasUnknownCriticalOption,
              hasFormatError: hasFormatError,
            );
          } else {
            return;
          }

          controller.add(coapMessage);
        } on UnknownCriticalOptionException {
          // Should something be done here?
          return;
        } on FormatException {
          // Should something be done here?
          return;
        }
      },
      onDone: controller.close,
      onError: controller.addError,
      cancelOnError: cancelOnError,
    );
    controller
      ..onPause = subscription.pause
      ..onResume = subscription.resume
      ..onCancel = subscription.cancel;
  };

  return controller.stream.listen(null);
});

List<Option<Object?>> readOptions(final DatagramReader reader) {
  final options = <Option<Object?>>[];
  var currentOption = 0;
  while (reader.bytesAvailable) {
    final nextByte = reader.readNextByte();
    if (nextByte == message_format.payloadMarker) {
      if (!reader.bytesAvailable) {
        throw const FormatException('Illegal format');
        // The presence of a marker followed by a zero-length payload
        // must be processed as a message format error
      }
      break;
    } else {
      // The first 4 bits of the byte represent the option delta
      final optionDeltaNibble = (0xF0 & nextByte) >> 4;
      final deltaValue = _getValueFromOptionNibble(
        optionDeltaNibble,
        reader,
      );

      if (deltaValue == null) {
        throw const FormatException('Illegal format');
      }

      currentOption += deltaValue;

      // The second 4 bits represent the option length
      final optionLengthNibble = 0x0F & nextByte;
      final optionLength = _getValueFromOptionNibble(
        optionLengthNibble,
        reader,
      );

      if (optionLength == null) {
        throw const FormatException('Illegal format');
      }

      // Read option
      try {
        final optionType = OptionType.fromTypeNumber(currentOption);
        var optionBytes = reader.readBytes(optionLength);
        if (Endian.host == Endian.little &&
            optionType.optionFormat is OptionFormat<int>) {
          optionBytes = Uint8Buffer()..addAll(optionBytes.reversed);
        }
        final option = optionType.parse(optionBytes);
        options.add(option);
      } on UnknownElectiveOptionException catch (_) {
        // Unknown elective options must be silently ignored
        continue;
      }
    }
  }

  return options;
}

/// Calculates the value used in the extended option fields as specified
/// in RFC 7252, section 3.1.
int? _getValueFromOptionNibble(
  final int nibble,
  final DatagramReader datagram,
) =>
    _readExtendedLength(nibble, datagram);

int? _readExtendedLength(
  final int value,
  final DatagramReader datagram,
) {
  if (value < 13) {
    return value;
  } else if (value == 13) {
    return datagram.read(8) + 13;
  } else if (value == 14) {
    return datagram.read(16) + 269;
  }

  return null;
}

int _readExtendedMessageLength(
  final int value,
  final DatagramReader datagramReader,
) {
  switch (value) {
    case 13:
      return datagramReader.read(8) + 13;
    case 14:
      return datagramReader.read(16) + 269;
    case 15:
      return datagramReader.read(32) + 65805;
  }

  throw StateError('Illegal value read');
}
