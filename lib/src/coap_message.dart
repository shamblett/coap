/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/05/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// The class Message models the base class of all CoAP messages.
/// CoAP messages are of type Request, Response or EmptyMessage,
/// each of which has a MessageType, a message identifier,
/// a token (0-8 bytes), a collection of Options and a payload.
class Message extends Object with events.EventEmitter {
  /// Indicates that no ID has been set.
  static const int none = -1;

  /// Invalid message ID.
  static const int invalidID = none;

  int type = MessageType.unknown;
  int code;
  int id = none;
  typed.Uint8Buffer _token;

  typed.Uint8Buffer get token => _token;

  String get tokenString => _token.toString();

  set token(typed.Uint8Buffer value) {
    if (value != null && value.length <= 8) {
      _token = value;
    }
  }

  typed.Uint8Buffer _payload;
  String _payloadString;

  typed.Uint8Buffer get payload => _payload;

  set payload(typed.Uint8Buffer value) {
    _payload = value;
    _payloadString = null;
  }

  int get payloadSize => null == _payload ? 0 : _payload.length;
}
