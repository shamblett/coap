/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 14/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

class CoapMessageDecoder03 extends CoapMessageDecoder {
  CoapMessageDecoder03(typed.Uint8Buffer data) : super(data) {
    readProtocol();
  }

  int _optionCount;
}
