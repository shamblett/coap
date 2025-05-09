/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 05/06/2018
 * Copyright :  S.Hamblett
 */

import 'dart:async';

import 'package:coap/src/option/coap_option_type.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'coap_request.dart';
import 'coap_response.dart';
import 'option/integer_option.dart';

/// Represents a CoAP observe relation between a CoAP client and a
/// resource on a server.
/// Provides a simple API to check whether a relation has successfully
/// established and to cancel or refresh the relation.
class CoapObserveClientRelation extends Stream<CoapResponse> {
  final CoapRequest _request;

  final Stream<CoapResponse> _responseStream;

  bool _cancelled = false;

  /// Cancelled
  bool get isCancelled => _cancelled;

  Stream<CoapResponse> get _filteredStream => _responseStream
      .where(_responseTokenIsMatched)
      .takeWhile((final _) => _request.isActive);

  @internal
  set isCancelled(final bool val) {
    _request.isCancelled = val;
    _cancelled = val;
  }

  /// Construction
  CoapObserveClientRelation(this._request, this._responseStream);

  @override
  StreamSubscription<CoapResponse> listen(
    final void Function(CoapResponse event)? onData, {
    final Function? onError,
    final void Function()? onDone,
    final bool? cancelOnError,
  }) => _filteredStream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  void checkObserve() {
    _filteredStream.first.then((final resp) {
      if (!resp.hasOption<ObserveOption>()) {
        isCancelled = true;
      }
    });
  }

  /// Create a cancellation request
  @internal
  CoapRequest cancellation() =>
      CoapRequest.get(_request.uri)
        // Copy options except for URI host and Path, but set Observe to cancel
        ..setOptions(
          _request.getAllOptions().skipWhile(
            (option) =>
                option.type == OptionType.uriHost ||
                option.type == OptionType.uriPath,
          ),
        )
        ..observe = ObserveRegistration.deregister.value
        // Use same Token
        ..token = _request.token
        ..destination = _request.destination
        // Dispatch final response to the same message observers
        ..copyEventHandler(_request);

  bool _responseTokenIsMatched(final CoapResponse response) {
    final requestToken = _request.token;
    final responseToken = response.token;

    if (requestToken == null || responseToken == null) {
      return false;
    }

    return requestToken.equals(responseToken);
  }
}
