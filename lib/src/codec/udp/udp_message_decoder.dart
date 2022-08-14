/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

import 'package:typed_data/typed_data.dart';

import '../../coap_code.dart';
import '../../coap_constants.dart';
import '../../coap_empty_message.dart';
import '../../coap_message.dart';
import '../../coap_message_type.dart';
import '../../coap_option.dart';
import '../../coap_option_type.dart';
import '../../coap_request.dart';
import '../../coap_response.dart';
import 'datagram_reader.dart';
import 'message_format.dart' as message_format;

/// Provides methods to parse incoming byte arrays to messages.
class CoapMessageDecoder {
  /// Instantiates.
  CoapMessageDecoder(final Uint8Buffer data) : reader = DatagramReader(data) {
    readProtocol();
  }

  /// The bytes reader
  final DatagramReader reader;

  /// Checks if the decoding message is well formed.
  bool get isWellFormed => version == message_format.version;

  int? _version;

  /// Gets the version of the decoding message.
  int? get version => _version;

  int _tokenLength = 0;

  int? _id;

  /// Gets the id of the decoding message.
  int? get id => _id;

  /// Reads protocol headers.
  void readProtocol() {
    // Read headers
    _version = reader.read(message_format.versionBits);
    _type = reader.read(message_format.typeBits);
    _tokenLength = reader.read(message_format.tokenLengthBits);
    _code = reader.read(message_format.codeBits);
    _id = reader.read(message_format.idBits);
  }

  int? _type;

  /// The type of the decoding message
  int? get type => _type;

  int? _code;

  /// The code of the decoding message
  int? get code => _code;

  /// Parses the rest data other than protocol headers into the given message.
  void parseMessage(final CoapMessage message) {
    // Read token
    if (_tokenLength > 0) {
      message.token = reader.readBytes(_tokenLength);
    } else {
      message.token = CoapConstants.emptyToken;
    }
    // Read options
    var currentOption = 0;
    while (reader.bytesAvailable) {
      final nextByte = reader.readNextByte();
      if (nextByte == message_format.payloadMarker) {
        if (!reader.bytesAvailable) {
          // The presence of a marker followed by a zero-length payload
          // must be processed as a message format error
          throw const FormatException('Marker followed by 0 length payload');
        }

        message.payload = reader.readBytesLeft();
      } else {
        // The first 4 bits of the byte represent the option delta
        final optionDeltaNibble = (0xF0 & nextByte) >> 4;
        currentOption += _getValueFromOptionNibble(
          optionDeltaNibble,
          reader,
        );

        // The second 4 bits represent the option length
        final optionLengthNibble = 0x0F & nextByte;
        final optionLength = _getValueFromOptionNibble(
          optionLengthNibble,
          reader,
        );

        // Read option
        final CoapOption opt;
        try {
          final optionType = OptionType.fromTypeNumber(currentOption);
          opt = CoapOption.create(optionType);
        } on UnknownElectiveOptionException catch (_) {
          // Unknown elective options must be silently ignored
          continue;
        } on UnknownCriticalOptionException catch (_) {
          // Messages with unknown critical options must be rejected
          message.hasUnknownCriticalOption = true;
          return;
        }
        opt.byteValue = reader.readBytes(optionLength);
        // Reverse byte order for numeric options
        if (opt.type.optionFormat == OptionFormat.integer) {
          opt.byteValue = Uint8Buffer()..addAll(opt.byteValue.reversed);
        }

        message.addOption(opt);
      }
    }
  }

  CoapMessageType? get _decodedType {
    final type_ = type;
    if (type_ == null) {
      return null;
    }
    return CoapMessageType.decode(type_);
  }

  CoapCode? get _decodedCode {
    final code_ = code;
    if (code_ == null) {
      return null;
    }
    return CoapCode.decode(code_);
  }

  /// Checks if the decoding message is a reply.
  bool get isReply =>
      type == CoapMessageType.ack.code || type == CoapMessageType.rst.code;

  /// Checks if the decoding message is a request.
  bool get isRequest => _decodedCode?.isRequest ?? false;

  /// Checks if the decoding message is a response.
  bool get isResponse => _decodedCode?.isResponse ?? false;

  /// Checks if the decoding message is an empty message.
  bool get isEmpty => _decodedCode?.isEmpty ?? false;

  /// Decodes as a Request.
  CoapRequest? decodeRequest() {
    final decodedCode = _decodedCode;

    if (decodedCode != null && isRequest) {
      final request = CoapRequest(
        decodedCode,
        confirmable: type == CoapMessageType.con.code,
      )..id = id;
      parseMessage(request);
      return request;
    }
    return null;
  }

  /// Decodes as a Response.
  CoapResponse? decodeResponse() {
    final decodedCode = _decodedCode;
    final coapMessageType = _decodedType;

    if (!isResponse || decodedCode == null || coapMessageType == null) {
      return null;
    }

    final response = CoapResponse(decodedCode, coapMessageType)..id = id;
    parseMessage(response);
    return response;
  }

  /// Decodes as an EmptyMessage.
  CoapEmptyMessage? decodeEmptyMessage() {
    final coapMessageType = _decodedType;
    if (coapMessageType == null || !isEmpty) {
      return null;
    }

    final message = CoapEmptyMessage(coapMessageType)..id = id;
    parseMessage(message);
    return message;
  }

  /// Decodes as a CoAP message.
  CoapMessage? decodeMessage() {
    if (isRequest) {
      return decodeRequest();
    } else if (isResponse) {
      return decodeResponse();
    } else if (isEmpty) {
      return decodeEmptyMessage();
    } else {
      return null;
    }
  }

  /// Calculates the value used in the extended option fields as specified
  /// in RFC 7252, section 3.1.
  int _getValueFromOptionNibble(
    final int nibble,
    final DatagramReader datagram,
  ) {
    if (nibble < 13) {
      return nibble;
    } else if (nibble == 13) {
      return datagram.read(8) + 13;
    } else if (nibble == 14) {
      return datagram.read(16) + 269;
    } else {
      throw FormatException('Unsupported option delta $nibble');
    }
  }
}
