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
  int get length => _attributes.length;

  /// Is empty
  bool get isEmpty => _attributes.isEmpty;

  /// Is not empty
  bool get isNotEmpty => _attributes.isNotEmpty;

  /// Gets all the attribute names.
  Iterable<String> get keys => _attributes.keys;

  /// The resource title.
  String? get title => getValues(LinkFormatParameter.title.short)?.firstOrNull;

  /// Gets or sets a value indicating if the resource is observable.
  bool? get observable =>
      getValues(LinkFormatParameter.observable.short)?.firstOrNull?.isNotEmpty;

  /// Gets or sets the maximum size estimate string value.
  String? get maximumSizeEstimateString =>
      getValues(LinkFormatParameter.maxSizeEstimate.short)?.first;

  /// Gets or sets the maximum size estimate.
  int get maximumSizeEstimate =>
      int.tryParse(maximumSizeEstimateString ?? '') ?? 0;

  /// Gets all endpoint names.
  Iterable<String?>? get endpointNames =>
      _attributes[LinkFormatParameter.endpointName.short];

  /// Gets or sets the lifetime string value.
  String? get liftimeString =>
      getValues(LinkFormatParameter.lifetime.short)?.first;

  /// Gets or sets the page string value.
  String? get pageString => getValues(LinkFormatParameter.page.short)?.first;

  /// Gets or sets the page.
  int get page => int.tryParse(pageString ?? '') ?? 0;

  /// Gets or sets the lifetime.
  int get lifetime => int.tryParse(liftimeString ?? '') ?? 0;

  /// Gets or sets the count string value.
  String? get countString => getValues(LinkFormatParameter.count.short)?.first;

  /// Gets or sets the count.
  int get count => int.tryParse(countString ?? '') ?? 0;

  /// Gets all endpoint types.
  Iterable<String?>? get endpointTypes =>
      _attributes[LinkFormatParameter.endpointType.short];

  set pageString(final String? value) =>
      set(LinkFormatParameter.page.short, value);

  set maximumSizeEstimate(final int value) =>
      maximumSizeEstimateString = value.toString();

  set observable(final bool? value) =>
      set(LinkFormatParameter.observable.short, '');

  set title(final String? value) => set(LinkFormatParameter.title.short, value);

  set maximumSizeEstimateString(final String? value) =>
      set(LinkFormatParameter.maxSizeEstimate.short, value);

  set liftimeString(final String? value) =>
      set(LinkFormatParameter.lifetime.short, value);

  set lifetime(final int value) => liftimeString = value.toString();

  set page(final int value) => pageString = value.toString();

  set countString(final String? value) =>
      set(LinkFormatParameter.count.short, value);

  set count(final int value) => countString = value.toString();

  /// Adds a resource type.
  void addResourceType(final String type) {
    _attributes[LinkFormatParameter.resourceType.short]!.add(type);
  }

  /// Gets all resource types.
  Iterable<String?>? getResourceTypes() =>
      _attributes[LinkFormatParameter.resourceType.short];

  /// Clears all resource types.
  void clearResourceTypes() {
    _attributes[LinkFormatParameter.resourceType.short] = <String>[];
  }

  /// Adds an interface description.
  void addInterfaceDescription(final String description) {
    _attributes[LinkFormatParameter.interfaceDescription.short]!.add(
      description,
    );
  }

  /// Gets all interface descriptions.
  Iterable<String?>? getInterfaceDescriptions() =>
      _attributes[LinkFormatParameter.interfaceDescription.short];

  /// Clears all interface descriptions.
  void clearInterfaceDescriptions() {
    _attributes[LinkFormatParameter.interfaceDescription.short] = <String>[];
  }

  /// Adds a content type specified by an integer.
  void addContentType(final int type) {
    _attributes[LinkFormatParameter.contentType.short]!.add(type.toString());
  }

  /// Gets all content types.
  Iterable<String?>? getContentTypes() =>
      _attributes[LinkFormatParameter.contentType.short];

  /// Clears all content types.
  void clearContentTypes() {
    _attributes[LinkFormatParameter.contentType.short] = <String>[];
  }

  /// Adds an [endpointName] specified by an [String].
  void addEndpointName(final String endpointName) {
    _attributes[LinkFormatParameter.endpointName.short]!.add(endpointName);
  }

  /// Clears all endpoint names.
  void clearEndpointNames() {
    _attributes[LinkFormatParameter.endpointName.short] = <String>[];
  }

  /// Adds an [endpointType] specified by an [String].
  void addEndpointType(final String endpointType) {
    _attributes[LinkFormatParameter.endpointType.short]!.add(endpointType);
  }

  /// Clears all resource types.
  void clearEndpointTypes() {
    _attributes[LinkFormatParameter.endpointType.short] = <String>[];
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
