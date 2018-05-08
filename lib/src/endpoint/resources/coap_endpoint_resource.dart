/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 08/05/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// This class describes the functionality of a CoAP endpoint resource.
abstract class CoapEndpointResource {
  static CoapILogger _log = new CoapLogManager("console").logger;

  int _totalSubResourceCount;
  String _resourceIdentifier;

  String get name => _resourceIdentifier;

  set name(String value) => _resourceIdentifier = value;

  HashSet<CoapLinkAttribute> _attributes;

  Iterable get attributes => _attributes;

  CoapEndpointResource _parent;
  SplayTreeMap<String, CoapEndpointResource> _subResources;
  bool _hidden;

  bool get hidden => _hidden;

  set hidden(bool state) => _hidden = state;

  /// Initialize a resource.
  CoapEndpointResource(this._resourceIdentifier);

  /// Initialize a resource.
  CoapEndpointResource.hide(String resourceIdentifier, bool hidden) {
    this._resourceIdentifier = resourceIdentifier;
    this._hidden = hidden;
    this._attributes = new HashSet<CoapLinkAttribute>();
  }

  /// Gets the URI of this resource.
  String get path {
    StringBuffer sb = new StringBuffer();
    sb.write(name);
    if (_parent == null)
      sb.write("/");
    else {
      CoapEndpointResource res = _parent;
      while (res != null) {
        final StringBuffer tmp =
            new StringBuffer("/${res.name}${sb.toString()}");
        sb = tmp;
        res = res._parent;
      }
    }
    return sb.toString();
  }

  List<CoapLinkAttribute> getAttributes(String name) {
    final List<CoapLinkAttribute> list = new List<CoapLinkAttribute>();
    for (CoapLinkAttribute attr in attributes) {
      if (attr.name == name) {
        list.add(attr);
      }
    }
    return list;
  }

  bool setAttribute(CoapLinkAttribute attr) {
    // Adds depending on the Link Format rules
    return CoapLinkFormat.addAttribute(attributes, attr);
  }

  bool clearAttribute(String name) {
    bool cleared = false;
    for (CoapLinkAttribute attr in getAttributes(name)) {
      cleared = cleared || _attributes.remove(attr);
    }
    return cleared;
  }

  static Iterable<String> getStringValues(
      Iterable<CoapLinkAttribute> attributes) {
    List<String> list = new List<String>();
    for (CoapLinkAttribute attr in attributes) {
      list.add(attr.valueAsString);
    }
    return list;
  }

  Iterable<String> get resourceTypes =>
      getStringValues(getAttributes(CoapLinkFormat.resourceType));
}
