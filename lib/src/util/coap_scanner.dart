/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

class CoapScanner {
  String _s;
  int _position;

  CoapScanner(String s) {
    _s = s;
    _position = 0;
  }

  String find(RegExp regex) {
    if (_position < _s.length) {
      final String tmp = _s.substring(_position);
      final Match m = regex.firstMatch(tmp);
      if (m != null) {
        _position = _position + (m.end - m.start);
        return m.group(0);
      }
    }
    return null;
  }

  String findExact(RegExp regex) {
    if (_position < _s.length) {
      final String tmp = _s.substring(_position);
      final Match m = regex.firstMatch(tmp);
      if (m != null) {
        if (m.start == 1) {
          _position = _position + (m.end - m.start) + 1;
          return m.group(0);
        }
      }
    }
    return null;
  }
}
