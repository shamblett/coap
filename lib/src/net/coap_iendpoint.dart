/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Represents a communication endpoint multiplexing CoAP message exchanges
/// between (potentially multiple) clients and servers.
abstract class CoapIEndPoint extends Object with events.EventEmitter {
}
