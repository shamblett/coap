/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

abstract class CoapIResource {
  /// The name of the resource.
  /// Note that changing the name of a resource changes
  /// the path and URI of all children.
  /// Note that the parent of this resource must be notified
  /// that the name has changed so that it finds the
  /// resource under the correct new URI when another request arrives.
  String name;

  /// the path to the resource which is equal to
  /// the URI of its parent plus a slash.
  /// Note that changing the path of a resource also changes
  /// the path of all its children.
  String path;

  /// The uri of the resource.
  String _uri;

  String get uri => _uri;

  /// Indicates if the resource is visible to remote CoAP clients.
  bool _visible;

  bool get visible => _visible;

  /// Indicates if is the URI of the resource can be cached.
  /// If another request with the same destination URI arrives,
  /// it can be forwarded to this resource right away instead of
  /// traveling through the resource tree looking for it.
  bool _cachable;

  bool get cachable => _cachable;

  /// Indicates if this resource is observable by remote CoAP clients.
  bool _observable;

  bool get observable => _observable;

  /// Gets the attributes of this resource.
  CoapResourceAttributes _attributes;

  CoapResourceAttributes get attributes => _attributes;

  /// Gets the executor of this resource.
  CoapIExecutor _executor;

  CoapIExecutor get executor => _executor;

  /// Gets the endpoints this resource is bound to.
  Iterable<CoapIEndPoint> _endPoints;

  Iterable<CoapIEndPoint> get endPoints => _endPoints;

  /// The parent of this resource.
  CoapIResource parent;

  /// Gets all child resources.
  Iterable<CoapIResource> _children;

  Iterable<CoapIResource> get children => _children;

  /// Adds the specified resource as child.
  void add(CoapIResource child);

  /// Removes the the specified child.
  /// Returns true if the child was found, otherwise false
  bool remove(CoapIResource child);

  /// Gets the child with the specified name.
  CoapIResource getChild(String name);

  /// Adds the specified CoAP observe relation.
  void addObserveRelation(CoapObserveRelation relation);

  /// Removes the specified CoAP observe relation.
  void removeObserveRelation(CoapObserveRelation relation);

  /// Handles the request from the specified exchange.
  void handleRequest(CoapExchange exchange);
}
