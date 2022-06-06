/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

import 'package:typed_data/typed_data.dart';

import '../coap_message.dart';
import '../codec/coap_imessage_decoder.dart';
import '../codec/coap_imessage_encoder.dart';

/// Represents a draft version of CoAP specification.
abstract class CoapISpec {
  /// Gets the name of this draft.
  String get name;

  /// Gets the default CoAP port in this draft.
  int get defaultPort;

  /// Gets the default CoAPS port in this draft.
  int get defaultSecurePort;

  /// Encodes a CoAP message into a bytes array.
  /// Returns the encoded bytes, or null if the message can not be encoded,
  /// i.e. the message is not a Request, a Response or an EmptyMessage.
  Uint8Buffer? encode(CoapMessage msg);

  /// Decodes a CoAP message from a bytes array.
  /// Returns the decoded message, or null if the bytes array
  /// can not be recognized.
  CoapMessage? decode(Uint8Buffer bytes);

  /// Gets an IMessageEncoder.
  CoapIMessageEncoder newMessageEncoder();

  /// Gets an IMessageDecoder.
  CoapIMessageDecoder newMessageDecoder(Uint8Buffer data);
}
