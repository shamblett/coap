/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Represents the complete state of an exchange of one request
/// and one or more responses. The lifecycle of an exchange ends
/// when either the last response has arrived and is acknowledged,
/// when a request or response has been rejected from the remote endpoint,
/// when the request has been canceled, or when a request or response timed out,
/// i.e., has reached the retransmission limit without being acknowledged.

class CoapExchange {
}