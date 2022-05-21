/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

import 'package:typed_data/typed_data.dart';

import '../../coap_message.dart';
import '../../codec/coap_imessage_decoder.dart';
import '../../codec/coap_imessage_encoder.dart';
import '../../codec/datagram/coap_datagram_reader.dart';
import '../../codec/decoders/coap_message_decoder_rfc7252.dart';
import '../../codec/encoders/coap_message_encoder_rfc7252.dart';
import '../coap_ispec.dart';

/// RFC 7252
class CoapRfc7252 implements CoapISpec {
  /// Version
  static const int version = 1;

  /// Version bit length
  static const int versionBits = 2;

  /// Type bit length
  static const int typeBits = 2;

  /// Token bit length
  static const int tokenLengthBits = 4;

  /// Code bit length
  static const int codeBits = 8;

  /// Id bit length
  static const int idBits = 16;

  /// Option delta bit length
  static const int optionDeltaBits = 4;

  /// Option length bit length
  static const int optionLengthBits = 4;

  /// Payload marker
  static const int payloadMarker = 0xFF;

  @override
  String get name => 'RFC 7252';

  @override
  int get defaultPort => 5683;

  @override
  int get defaultSecurePort => 5684;

  @override
  CoapIMessageEncoder newMessageEncoder() => CoapMessageEncoderRfc7252();

  @override
  CoapIMessageDecoder newMessageDecoder(Uint8Buffer data) =>
      CoapMessageDecoder18(data);

  @override
  Uint8Buffer? encode(CoapMessage msg) =>
      newMessageEncoder().encodeMessage(msg);

  @override
  CoapMessage? decode(Uint8Buffer bytes) =>
      newMessageDecoder(bytes).decodeMessage();

  /// Calculates the value used in the extended option fields as specified
  /// in RFC 7252, section 3.1.
  static int getValueFromOptionNibble(int nibble, CoapDatagramReader datagram) {
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

  /// Returns the 4-bit option header value.
  static int getOptionNibble(int optionValue) {
    if (optionValue <= 12) {
      return optionValue;
    } else if (optionValue <= 255 + 13) {
      return 13;
    } else if (optionValue <= 65535 + 269) {
      return 14;
    } else {
      throw FormatException('Unsupported option delta $optionValue');
    }
  }
}
