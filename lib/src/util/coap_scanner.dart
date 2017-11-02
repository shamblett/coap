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
    return _find(regex);
  }

  String _find(RegExp regex) {
    if (_position < _s.length) {
      final Match m = regex.matchAsPrefix(_s, _position);
      if (m != null) {
        _position = m.end;
        return m.group(0);
      }
    }
    return null;
  }
}
