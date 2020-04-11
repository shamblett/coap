/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// String scanner
class CoapScanner extends scanner.StringScanner {
  /// Construction
  CoapScanner(String source) : super(source);

  /// Take characters from the source string advancing the position up
  /// to but not including the stop character and return as a string
  String takeUntil(String stopCharacter) {
    final buff = StringBuffer();
    try {
      while (peekChar(0) != stopCharacter.codeUnitAt(0)) {
        buff.write(String.fromCharCode(readChar()));
      }
    } on scanner.StringScannerException {
      // If we run out of string return what we have
      return buff.toString();
    }
    return buff.toString();
  }
}
