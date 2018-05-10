/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 08/05/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// This class describes the functionality of a CoAP endpoint resource.
abstract class CoapEndpointResource {
  /// Initialize a resource.
  CoapEndpointResource(this._resourceIdentifier);

  /// Initialize a resource.
  CoapEndpointResource.hide(String resourceIdentifier, bool hidden) {
    this._resourceIdentifier = resourceIdentifier;
    this._hidden = hidden;
    this._attributes = new HashSet<CoapLinkAttribute>();
  }

  static CoapILogger _log = new CoapLogManager("console").logger;

  String _resourceIdentifier;

  String get name => _resourceIdentifier;

  set name(String value) => _resourceIdentifier = value;

  HashSet<CoapLinkAttribute> _attributes;

  Iterable get attributes => _attributes;

  CoapEndpointResource _parent;
  SplayTreeMap<String, CoapEndpointResource> _subResources;

  SplayTreeMap<String, CoapEndpointResource> get subResources => _subResources;

  int _totalSubResourceCount;

  /// Gets the total count of sub-resources, including children and children's children...
  int get totalSubResourceCount => _totalSubResourceCount;

  /// Gets the count of sub-resources of this resource.
  int get subResourceCount => null == _subResources ? 0 : _subResources.length;

  bool _hidden = false;

  bool get hidden => _hidden;

  set hidden(bool state) => _hidden = state;

  String get resourceType =>
      getAttributes(CoapLinkFormat.resourceType).length == 0
          ? null
          : getAttributes(CoapLinkFormat.resourceType)[0].valueAsString;

  set resourceType(String value) =>
      setAttribute(new CoapLinkAttribute(CoapLinkFormat.resourceType, value));

  String get title =>
      getAttributes(CoapLinkFormat.title).length == 0
          ? null
          : getAttributes(CoapLinkFormat.title)[0].valueAsString;

  set title(String value) {
    clearAttribute(CoapLinkFormat.title);
    setAttribute(new CoapLinkAttribute(CoapLinkFormat.resourceType, value));
  }

  List<String> get interfaceDescriptions =>
      getStringValues(getAttributes(CoapLinkFormat.interfaceDescription));

  String get interfaceDescription =>
      getAttributes(CoapLinkFormat.interfaceDescription).length == 0
          ? null
          : getAttributes(CoapLinkFormat.interfaceDescription)[0].valueAsString;

  set interfaceDescription(String value) =>
      setAttribute(
          new CoapLinkAttribute(CoapLinkFormat.interfaceDescription, value));

  List<int> get contentTypeCodes =>
      getIntValues(getAttributes(CoapLinkFormat.contentType));

  int get contentTypeCode =>
      getAttributes(CoapLinkFormat.contentType).length == 0
          ? null
          : getAttributes(CoapLinkFormat.contentType)[0].valueAsInt;

  set contentTypeCode(int value) =>
      setAttribute(new CoapLinkAttribute(CoapLinkFormat.contentType, value));

  int get maximumSizeEstimate =>
      getAttributes(CoapLinkFormat.maxSizeEstimate).length == 0
          ? null
          : getAttributes(CoapLinkFormat.maxSizeEstimate)[0].valueAsInt;

  set maximumSizeEstimate(int value) =>
      setAttribute(
          new CoapLinkAttribute(CoapLinkFormat.maxSizeEstimate, value));

  bool get observable => getAttributes(CoapLinkFormat.observable).length > 0;

  set observable(bool value) {
    if (value)
      setAttribute(new CoapLinkAttribute(CoapLinkFormat.observable, value));
    else
      clearAttribute(CoapLinkFormat.observable);
  }

  Iterable<String> get resourceTypes =>
      getStringValues(getAttributes(CoapLinkFormat.resourceType));

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
    final List<String> list = new List<String>();
    for (CoapLinkAttribute attr in attributes) {
      list.add(attr.valueAsString);
    }
    return list;
  }

  static Iterable<int> getIntValues(Iterable<CoapLinkAttribute> attributes) {
    final List<int> list = new List<int>();
    for (CoapLinkAttribute attr in attributes) {
      list.add(attr.valueAsInt);
    }
    return list;
  }

  /// Removes this resource from its parent.
  void remove() {
    if (_parent != null) _parent.removeSubResource(this);
  }

  /// Gets sub-resources of this resource.
  List<CoapEndpointResource> getSubResources() {
    if (null == _subResources) {
      return null;
    }

    final List<CoapEndpointResource> resources =
    new List<CoapEndpointResource>(_subResources.length);
    resources.addAll(_subResources.values);
    return resources;
  }

  /// Removes a sub-resource from this resource.
  void removeSubResource(CoapEndpointResource resource) {
    if (null == resource) return;

    if ((_subResources.remove(resource._resourceIdentifier)) != null) {
      CoapEndpointResource p = resource._parent;
      while (p != null) {
        p._totalSubResourceCount--;
        p = p._parent;
      }

      resource._parent = null;
    }
  }

  CoapEndpointResource getResourcePath(String path) {
    return getResource(path, false);
  }

  CoapEndpointResource getResource(String path, bool last) {
    if (path.isEmpty) return this;

    // find root for absolute path
    if (path.startsWith("/")) {
      CoapEndpointResource root = this;
      while (root._parent != null) root = root._parent;
      final String path1 = path == "/" ? null : path.substring(1);
      return root.getResourcePath(path1);
    }

    final int pos = path.indexOf('/');
    String head = null,
        tail = null;

    // note: "some/resource/" addresses a resource "" under "resource"
    if (pos == -1) {
      head = path;
    } else {
      head = path.substring(0, pos);
      tail = path.substring(pos + 1);
    }

    if (_subResources.containsKey(head))
      return _subResources[head].getResource(tail, last);
    else if (last)
      return this;
    else
      return null;
  }

  /// Adds a resource as a sub-resource of this resource.
  void addSubResource(CoapEndpointResource resource) {
    if (null == resource) throw new ArgumentError.notNull("resource");

    // no absolute paths allowed, use root directly
    while (resource.name.startsWith("/")) {
      if (_parent != null) {
        _log.warn("Adding absolute path only allowed for root: made relative " +
            resource.name);
      }
      resource.name = resource.name.substring(1);
    }

    // Get last existing resource along path
    CoapEndpointResource baseRes = getResource(resource.name, true);

    String path = this.path;
    if (!path.endsWith("/")) path += "/";
    path += resource.name;

    path = path.substring(baseRes.path.length);
    if (path.startsWith("/")) path = path.substring(1);

    if (path.length == 0) {
      // resource replaces base
      _log.info("Replacing resource " + baseRes.path);
      for (CoapEndpointResource sub in baseRes.getSubResources()) {
        sub._parent = resource;
        resource.subResources[sub.name] = sub;
      }
      resource._parent = baseRes._parent;
      baseRes._parent.subResources[baseRes.name] = resource;
    } else {
      // resource is added to base

      final List<String> segments = path.split('/');
      if (segments.length > 1) {
        _log.debug("Splitting up compound resource " + resource.name);
        resource.name = segments[segments.length - 1];

        // insert middle segments
        CoapEndpointResource sub = null;
        for (int i = 0; i < segments.length - 1; i++) {
          sub = baseRes.createInstance(segments[i]);
          sub.hidden = true;
          baseRes.addSubResource(sub);
          baseRes = sub;
        }
      } else
        resource.name = path;

      resource._parent = baseRes;
      baseRes.subResources[resource.name] = resource;

      _log.debug("Add resource " + resource.name);
    }

    // update number of sub-resources in the tree
    CoapEndpointResource p = resource._parent;
    while (p != null) {
      p._totalSubResourceCount++;
      p = p._parent;
    }
  }

  /// Removes a sub-resource from this resource by its identifier.
  void removeSubResourcePath(String resourcePath) {
    removeSubResource(getResourcePath(resourcePath));
  }

  void createSubResource(CoapRequest request, String newIdentifier) {
    doCreateSubResource(request, newIdentifier);
  }

  /// Creates a resouce instance with proper subtype.
  CoapEndpointResource createInstance(String name);

  void doCreateSubResource(CoapRequest request, String newIdentifier);
}
