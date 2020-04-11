/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Represents an observing endpoint. It holds all observe relations
/// that the endpoint has to this server. If a confirmable notification timeouts
/// for the maximum times allowed the server assumes the client is no longer
/// reachable and cancels all relations that it has established to resources.
class CoapObservingEndpoint {
  /// Constructs a new observing endpoint.
  CoapObservingEndpoint(InternetAddress ep) {
    _endpoint = ep;
  }

  InternetAddress _endpoint;

  /// The endpoint
  InternetAddress get endpoint => _endpoint;
  final List<CoapObserveRelation> _relations = <CoapObserveRelation>[];

  /// Adds the specified observe relation.
  void addObserveRelation(CoapObserveRelation relation) {
    _relations.add(relation);
  }

  /// Removes the specified observe relation.
  void removeObserveRelation(CoapObserveRelation relation) {
    _relations.remove(relation);
  }

  /// Finds the observe relation by token.
  CoapObserveRelation getObserveRelation(typed.Uint8Buffer token) {
    for (final relation in _relations) {
      if (CoapByteArrayUtil.equals(token, relation.exchange.request.token)) {
        return relation;
      }
    }
    return null;
  }

  /// Cancels all observe relations that this endpoint has established with
  /// resources from this server.
  void cancelAll() {
    for (final relation in _relations) {
      relation.cancel();
    }
  }
}
