/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

import 'package:collection/collection.dart';

import '../coap_link_format.dart';

/// Wraps different attributes that the CoAP protocol defines
/// such as title, resource type or interface description. These attributes will
/// also be included in the link description of the resource they belong to. For
/// example, if a title was specified, the link description
/// for a sensor resource might look like this &lt;/sensors&gt;;title="Sensor Index"
class CoapResourceAttributes {
  final Map<String, List<String?>> _attributes = <String, List<String>>{};

  /// Gets the number of attributes.
  int get count => _attributes.length;

  /// Is empty
  bool get isEmpty => _attributes.isEmpty;

  /// Is not empty
  bool get isNotEmpty => _attributes.isNotEmpty;

  /// Gets all the attribute names.
  Iterable<String> get keys => _attributes.keys;

  /// The resource title.
  String? get title => getValues(CoapLinkFormat.title)?.firstOrNull;

  set title(final String? value) => set(CoapLinkFormat.title, value);

  /// Gets or sets a value indicating if the resource is observable.
  bool? get observable =>
      getValues(CoapLinkFormat.observable)?.firstOrNull?.isNotEmpty;

  set observable(final bool? value) => set(CoapLinkFormat.observable, '');

  /// Gets or sets the maximum size estimate string value.
  String? get maximumSizeEstimateString =>
      getValues(CoapLinkFormat.maxSizeEstimate)!.first;

  set maximumSizeEstimateString(final String? value) =>
      set(CoapLinkFormat.maxSizeEstimate, value);

  /// Gets or sets the maximum size estimate.
  int get maximumSizeEstimate => maximumSizeEstimateString!.isEmpty
      ? 0
      : int.parse(maximumSizeEstimateString!);

  set maximumSizeEstimate(final int value) =>
      maximumSizeEstimateString = value.toString();

  /// Adds a resource type.
  void addResourceType(final String type) {
    _attributes[CoapLinkFormat.resourceType]!.add(type);
  }

  /// Gets all resource types.
  Iterable<String?>? getResourceTypes() =>
      _attributes[CoapLinkFormat.resourceType];

  /// Clears all resource types.
  void clearResourceTypes() {
    _attributes[CoapLinkFormat.resourceType] = <String>[];
  }

  /// Adds an interface description.
  void addInterfaceDescription(final String description) {
    _attributes[CoapLinkFormat.interfaceDescription]!.add(description);
  }

  /// Gets all interface descriptions.
  Iterable<String?>? getInterfaceDescriptions() =>
      _attributes[CoapLinkFormat.interfaceDescription];

  /// Clears all interface descriptions.
  void clearInterfaceDescriptions() {
    _attributes[CoapLinkFormat.interfaceDescription] = <String>[];
  }

  /// Adds a content type specified by an integer.
  void addContentType(final int type) {
    _attributes[CoapLinkFormat.contentType]!.add(type.toString());
  }

  /// Gets all content types.
  Iterable<String?>? getContentTypes() =>
      _attributes[CoapLinkFormat.contentType];

  /// Clears all content types.
  void clearContentTypes() {
    _attributes[CoapLinkFormat.contentType] = <String>[];
  }

  /// Returns true if this object contains the specified attribute.
  bool contains(final String name) => _attributes.containsKey(name);

  /// Adds the specified value to the other values of the specified attribute.
  void add(final String name, final String value) {
    if (_attributes[name] == null) {
      _attributes[name] = <String>[];
    }
    _attributes[name]!.add(value);
  }

  /// Adds an arbitrary attribute with no value.
  void addNoValue(final String name) {
    add(name, '');
  }

  /// Gets all values for the specified attribute.
  Iterable<String?>? getValues(final String name) => _attributes[name];

  /// Replaces the value for the specified attribute with the specified value.
  /// If another value has been set for the attribute name, it will be removed.
  void set(final String name, final String? value) {
    if (_attributes[name] == null) {
      _attributes[name] = List<String>.filled(1, '');
    }
    _attributes[name]![0] = value;
  }

  /// Removes all values for the specified attribute.
  void clear(final String name) {
    _attributes[name] = <String>[];
  }
}
