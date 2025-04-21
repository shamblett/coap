/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

import 'dart:collection';
import 'dart:io';

import '../coap_config.dart';
import '../coap_response.dart';
import '../link-format/resources/coap_resource.dart';
import '../net/exchange.dart';
import 'coap_observing_endpoint.dart';

/// Represents a relation between a client endpoint and a resource on the
/// server.
class CoapObserveRelation {
  final DefaultCoapConfig config;

  /// Current control notification
  CoapResponse? currentControlNotification;

  /// Next control notification
  CoapResponse? nextControlNotification;

  /// A value indicating if this relation has been established
  bool established;

  final CoapObservingEndpoint _endpoint;

  final CoapResource _resource;

  final CoapExchange _exchange;

  DateTime _interestCheckTime = DateTime.now();

  int _interestCheckCounter = 1;

  // The notifications that have been sent, so they can be
  // removed from the Matcher.
  final Queue<CoapResponse?> _notifications = Queue<CoapResponse?>();

  /// Source endpoint of the observing endpoint
  InternetAddress? get source => _endpoint.endpoint;

  /// The resource
  CoapResource? get resource => _resource;

  /// The exchange
  CoapExchange get exchange => _exchange;

  /// Key
  String get key => '$source#${_exchange.request.tokenString}';

  /// Constructs a new observe relation.
  ///
  /// Takes the observing [endpoint], the observed [resource], and the
  /// [exchange] that tries to establish the observe relation as arguments.
  CoapObserveRelation(
    this.config,
    final CoapObservingEndpoint endpoint,
    final CoapResource resource,
    final CoapExchange exchange,
  ) : _endpoint = endpoint,
      _resource = resource,
      _exchange = exchange,
      established = true;

  /// Cancel this observe relation.
  void cancel() {
    // Stop ongoing retransmissions
    if (_exchange.response != null) {
      _exchange.response!.isCancelled = true;
    }
    established = false;
    _resource.removeObserveRelation(this);
    _endpoint.removeObserveRelation(this);
    _exchange.complete = true;
  }

  /// Cancel all observer relations that this server has
  /// established with this's realtion's endpoint.
  void cancelAll() {
    _endpoint.cancelAll();
  }

  /// Notifies the observing endpoint that the resource has been changed.
  void notifyObservers() {
    // Makes the resource process the same request again
    _resource.handleRequest(_exchange);
  }

  /// Check
  bool check() {
    var check = false;
    final now = DateTime.now();
    check =
        check ||
        _interestCheckTime
            .add(Duration(milliseconds: config.notificationCheckIntervalTime))
            .isBefore(now);
    check =
        check ||
        (++_interestCheckCounter >= config.notificationCheckIntervalCount);
    if (check) {
      _interestCheckTime = now;
      _interestCheckCounter = 0;
    }
    return check;
  }

  /// Add a notification
  void addNotification(final CoapResponse notification) {
    _notifications.add(notification);
  }

  /// Clear notifications
  Iterable<CoapResponse?> clearNotifications() {
    Iterable<CoapResponse?> list;
    list = _notifications.toList();
    _notifications.clear();
    return list;
  }
}
