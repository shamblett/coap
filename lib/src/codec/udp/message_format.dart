/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

/// The current CoAP version number
// TODO(JKRhb): Refactor into enum
const int version = 1;

/// Version bit length
const int versionBits = 2;

/// Type bit length
const int typeBits = 2;

/// Token bit length
const int tokenLengthBits = 4;

/// Code bit length
const int codeBits = 8;

/// Id bit length
const int idBits = 16;

/// Option delta bit length
const int optionDeltaBits = 4;

/// Option length bit length
const int optionLengthBits = 4;

/// Payload marker
const int payloadMarker = 0xFF;
