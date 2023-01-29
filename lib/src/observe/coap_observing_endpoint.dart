/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:typed_data/typed_data.dart';

import 'coap_observe_relation.dart';

/// Represents an observing endpoint. It holds all observe relations
/// that the endpoint has to this server. If a confirmable notification timeouts
/// for the maximum times allowed the server assumes the client is no longer
/// reachable and cancels all relations that it has established to resources.
class CoapObservingEndpoint {
  /// Constructs a new observing endpoint.
  CoapObservingEndpoint(this._endpoint);

  final InternetAddress _endpoint;

  /// The endpoint
  InternetAddress get endpoint => _endpoint;
  final List<CoapObserveRelation> _relations = <CoapObserveRelation>[];

  /// Adds the specified observe relation.
  void addObserveRelation(final CoapObserveRelation relation) {
    _relations.add(relation);
  }

  /// Removes the specified observe relation.
  void removeObserveRelation(final CoapObserveRelation relation) {
    _relations.remove(relation);
  }

  /// Finds the observe relation by token.
  CoapObserveRelation? getObserveRelation(final Uint8Buffer token) =>
      _relations.firstWhereOrNull(
        (final relation) => token.equals(relation.exchange.request.token!),
      );

  /// Cancels all observe relations that this endpoint has established with
  /// resources from this server.
  void cancelAll() {
    for (final relation in _relations) {
      relation.cancel();
    }
  }
}
