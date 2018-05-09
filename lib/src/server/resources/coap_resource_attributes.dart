/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Wraps different attributes that the CoAP protocol defines
/// such as title, resource type or interface description. These attributes will
/// also be included in the link description of the resource they belong to. For
/// example, if a title was specified, the link description for a sensor resource
/// might look like this &lt;/sensors&gt;;title="Sensor Index"
class CoapResourceAttributes {
  Map<String, List<String>> _attributes = new Map<String, List<String>>();

  /// Gets the number of attributes.
  int get count => _attributes.length;

  /// Gets all the attribute names.
  Iterable<String> get keys => _attributes.keys;

  /// The resource title.
  String get title => getValues(CoapLinkFormat.title).first;

  set title(String value) => set(CoapLinkFormat.title, value);

  /// Gets or sets a value indicating if the resource is observable.
  bool get observable => getValues(CoapLinkFormat.observable).first.isNotEmpty;

  set observable(bool value) => set(CoapLinkFormat.observable, "");

  /// Gets or sets the maximum size estimate string value.
  String get maximumSizeEstimateString =>
      getValues(CoapLinkFormat.maxSizeEstimate).first;

  set maximumSizeEstimateString(String value) =>
      set(CoapLinkFormat.maxSizeEstimate, value);

  /// Gets or sets the maximum size estimate.
  int get maximumSizeEstimate =>
      maximumSizeEstimateString.isEmpty
          ? 0
          : int.parse(maximumSizeEstimateString);

  set maximumSizeEstimate(int value) =>
      maximumSizeEstimateString = value.toString();

  /// Adds a resource type.
  void addResourceType(String type) {
    _attributes[CoapLinkFormat.resourceType].add(type);
  }

  /// Gets all resource types.
  Iterable<String> getResourceTypes() {
    return _attributes[CoapLinkFormat.resourceType];
  }

  /// Clears all resource types.
  void clearResourceTypes() {
    _attributes[CoapLinkFormat.resourceType] = new List<String>();
  }

  /// Adds an interface description.
  void addInterfaceDescription(String description) {
    _attributes[CoapLinkFormat.interfaceDescription].add(description);
  }

  /// Gets all interface descriptions.
  Iterable<String> getInterfaceDescriptions() {
    return _attributes[CoapLinkFormat.interfaceDescription];
  }

  /// Clears all interface descriptions.
  void clearInterfaceDescriptions() {
    _attributes[CoapLinkFormat.interfaceDescription] = new List<String>();
  }

  /// Adds a content type specified by an integer.
  void addContentType(int type) {
    _attributes[CoapLinkFormat.contentType].add(type.toString());
  }

  /// Gets all content types.
  Iterable<String> getContentTypes() {
    return _attributes[CoapLinkFormat.contentType];
  }

  /// Clears all content types.
  void clearContentTypes() {
    _attributes[CoapLinkFormat.contentType] = new List<String>();
  }

  /// Returns true if this object contains the specified attribute.
  bool contains(String name) {
    return _attributes.containsKey(name);
  }

  /// Adds the specified value to the other values of the specified attribute.
  void add(String name, String value) {
    _attributes[name].add(value);
  }

  /// Adds an arbitrary attribute with no value.
  void addNoValue(String name) {
    add(name, "");
  }

  /// Gets all values for the specified attribute.
  Iterable<String> getValues(String name) {
    return _attributes[name];
  }

  /// Replaces the value for the specified attribute with the specified value.
  /// If another value has been set for the attribute name, it will be removed.
  void set(String name, String value) {
    setOnly(_attributes[name], value);
  }

  static void setOnly(Iterable<String> values, String value) {
    final List<String> tmp = new List<String>();
    tmp[0] = value;
    values = tmp;
  }

  /// Removes all values for the specified attribute.
  void clear(String name) {
    _attributes[name] = new List<String>();
  }
}
