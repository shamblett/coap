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
}
