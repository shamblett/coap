/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

import '../../net/endpoint.dart';
import '../../net/exchange.dart';
import '../../observe/coap_observe_relation.dart';
import 'coap_resource_attributes.dart';

/// Interface for a resource
abstract class CoapResource {
  /// The name of the resource.
  /// Note that changing the name of a resource changes
  /// the path and URI of all children.
  /// Note that the parent of this resource must be notified
  /// that the name has changed so that it finds the
  /// resource under the correct new URI when another request arrives.
  String? name;

  /// the path to the resource which is equal to
  /// the URI of its parent plus a slash.
  /// Note that changing the path of a resource also changes
  /// the path of all its children.
  String? path;

  String? _uri;

  /// The uri of the resource.
  String? get uri => _uri;

  bool? _visible;

  /// Indicates if the resource is visible to remote CoAP clients.
  bool? get visible => _visible;

  bool? _cachable;

  /// Indicates if is the URI of the resource can be cached.
  /// If another request with the same destination URI arrives,
  /// it can be forwarded to this resource right away instead of
  /// traveling through the resource tree looking for it.
  bool? get cachable => _cachable;

  bool? _observable;

  /// Indicates if this resource is observable by remote CoAP clients.
  bool? get observable => _observable;

  CoapResourceAttributes? _attributes;

  /// Gets the attributes of this resource.
  CoapResourceAttributes? get attributes => _attributes;

  Iterable<Endpoint>? _endpoints;

  /// Gets the endpoints this resource is bound to.
  Iterable<Endpoint>? get endpoints => _endpoints;

  /// The parent of this resource.
  CoapResource? parent;

  Iterable<CoapResource>? _children;

  /// Gets all child resources.
  Iterable<CoapResource>? get children => _children;

  /// Adds the specified resource as child.
  void add(final CoapResource child);

  /// Removes the the specified child.
  /// Returns true if the child was found, otherwise false
  bool remove(final CoapResource child);

  /// Gets the child with the specified name.
  CoapResource getChild(final String name);

  /// Adds the specified CoAP observe relation.
  void addObserveRelation(final CoapObserveRelation relation);

  /// Removes the specified CoAP observe relation.
  void removeObserveRelation(final CoapObserveRelation relation);

  /// Handles the request from the specified exchange.
  void handleRequest(final CoapExchange? exchange);
}
