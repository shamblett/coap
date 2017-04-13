/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// CoAP option types as defined in
/// RFC 7252, Section 12.2 and other CoAP extensions.
class OptionType {
  static const int unknown = -1;
  static const int reserved = 0;

  /// C, opaque, 0-8 B, -
  static const int ifMatch = 1;

  /// C, String, 1-270 B, ""
  static const int uriHost = 3;

  /// E, sequence of bytes, 1-4 B, -
  static const int eTag = 4;
  static const int ifNoneMatch = 5;

  /// C, uint, 0-2 B
  static const int uriPort = 7;

  /// E, String, 1-270 B, -
  static const int locationPath = 8;

  /// C, String, 1-270 B, ""
  static const int uriPath = 11;

  /// C, 8-bit uint, 1 B, 0 (text/plain)
  /// <seealso cref="ContentFormat"/>
  static const int contentType = 12;

  /// C, 8-bit uint, 1 B, 0 (text/plain)
  static const int contentFormat = 12;

  /// E, variable length, 1--4 B, 60 Seconds
  static const int maxAge = 14;

  /// C, String, 1-270 B, ""
  static const int uriQuery = 15;

  /// C, Sequence of Bytes, 1-n B, -
  static const int accept = 17;

  /// C, Sequence of Bytes, 1-2 B, -. NOTE: this option has been replaced with <see cref="Message.Token"/> since draft 13.
  /// draft-ietf-core-coap-03, draft-ietf-core-coap-12</remarks>
  static const int token = 19;

  /// E, String, 1-270 B, -
  static const int locationQuery = 20;

  /// C, String, 1-270 B, "coap"
  static const int proxyUri = 35;
  static const int proxyScheme = 39;
  static const int size1 = 60;
  static const int reserved1 = 128;
  static const int reserved2 = 132;
  static const int reserved3 = 136;
  static const int reserved4 = 140;

  /// E, Duration, 1 B, 0
  static const int observe = 6;
  static const int block2 = 23;
  static const int block1 = 27;
  static const int size2 = 28;

  /// no-op for fenceposting
  static const int fencepostDivisor = 114;
}

/// CoAP option formats
enum optionFormat { integer, string, opaque, unknown }
