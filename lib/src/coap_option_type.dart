/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// CoAP option types as defined in
/// RFC 7252, Section 12.2 and other CoAP extensions.

const int optionTypeUnknown = -1;
const int optionTypeReserved = 0;

/// C, opaque, 0-8 B, -
const int optionTypeIfMatch = 1;

/// C, String, 1-270 B, ""
const int optionTypeUriHost = 3;

/// E, sequence of bytes, 1-4 B, -
const int optionTypeETag = 4;
const int optionTypeIfNoneMatch = 5;

/// C, uint, 0-2 B
const int optionTypeUriPort = 7;

/// E, String, 1-270 B, -
const int optionTypeLocationPath = 8;

/// C, String, 1-270 B, ""
const int optionTypeUriPath = 11;

/// C, 8-bit uint, 1 B, 0 (text/plain)
/// <seealso cref="ContentFormat"/>
const int optionTypeContentType = 12;

/// C, 8-bit uint, 1 B, 0 (text/plain)
const int optionTypeContentFormat = 12;

/// E, variable length, 1--4 B, 60 Seconds
const int optionTypeMaxAge = 14;

/// C, String, 1-270 B, ""
const int optionTypeUriQuery = 15;

/// C, Sequence of Bytes, 1-n B, -
const int optionTypeAccept = 17;

/// C, Sequence of Bytes, 1-2 B, -. NOTE: this option has been replaced with <see cref="Message.Token"/> since draft 13.
/// draft-ietf-core-coap-03, draft-ietf-core-coap-12</remarks>
const int optionTypeToken = 19;

/// E, String, 1-270 B, -
const int optionTypeLocationQuery = 20;

/// C, String, 1-270 B, "coap"
const int optionTypeProxyUri = 35;

const int optionTypeProxyScheme = 39;
const int optionTypeSize1 = 60;
const int optionTypeReserved1 = 128;
const int optionTypeReserved2 = 132;
const int optionTypeReserved3 = 136;
const int optionTypeReserved4 = 140;

/// E, Duration, 1 B, 0
const int optionTypeObserve = 6;

const int optionTypeBlock2 = 23;
const int optionTypeBlock1 = 27;
const int optionTypeSize2 = 28;

/// no-op for fenceposting
const int optionTypeFencepostDivisor = 114;

/// CoAP option formats
enum optionFormat { integer, string, opaque, unknown }
