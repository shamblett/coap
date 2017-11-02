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
  String _title;

}
