/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// This class describes the block options of the CoAP messages
class BlockOption extends Option {
  BlockOption(int type) : super(type);

}