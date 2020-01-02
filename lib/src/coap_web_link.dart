/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

// ignore_for_file: omit_local_variable_types
// ignore_for_file: unnecessary_final
// ignore_for_file: cascade_invocations
// ignore_for_file: avoid_print
// ignore_for_file: avoid_types_on_closure_parameters
// ignore_for_file: avoid_returning_this
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes
// ignore_for_file: prefer_null_aware_operators
// ignore_for_file: avoid_annotating_with_dynamic

/// This class can be used to programmatically browse a remote CoAP endoint.
class CoapWebLink extends Comparable<CoapWebLink> {
  /// Instantiates.
  CoapWebLink(String uri) {
    _uri = uri;
  }

  String _uri;

  /// The URI
  String get uri => _uri;
  final CoapResourceAttributes _attributes = CoapResourceAttributes();

  /// Attributes
  CoapResourceAttributes get attributes => _attributes;

  @override
  int compareTo(dynamic other) {
    if (other == null) {
      throw ArgumentError.notNull('CoapWebLink::other');
    }
    return _uri.compareTo(other._uri);
  }

  @override
  String toString() {
    final StringBuffer sb = StringBuffer();
    sb.write('<');
    sb.write(_uri);
    sb.write('>');
    sb.write(' ');
    if (_attributes.isNotEmpty) {
      if (_attributes.contains(CoapLinkFormat.title)) {
        sb.write('\n\t');
        sb.write(CoapLinkFormat.title);
        sb.write(':\t');
        sb.write(_attributes.title);
      }
      if (_attributes.contains(CoapLinkFormat.resourceType)) {
        sb.write('\n\t');
        sb.write(CoapLinkFormat.resourceType);
        sb.write(':\t');
        sb.write(_attributes.getResourceTypes());
      }
      if (_attributes.contains(CoapLinkFormat.interfaceDescription)) {
        sb.write('\n\t');
        sb.write(CoapLinkFormat.interfaceDescription);
        sb.write(':\t');
        sb.write(_attributes.getInterfaceDescriptions());
      }
      if (_attributes.contains(CoapLinkFormat.contentType)) {
        sb.write('\n\t');
        sb.write(CoapLinkFormat.contentType);
        sb.write(':\t');
        sb.write(_attributes.getContentTypes());
      }
      if (_attributes.contains(CoapLinkFormat.maxSizeEstimate)) {
        sb.write('\n\t');
        sb.write(CoapLinkFormat.maxSizeEstimate);
        sb.write(':\t');
        sb.write(_attributes.maximumSizeEstimate);
      }
      if (_attributes.observable != null) {
        sb.write('\n\t');
        sb.write(CoapLinkFormat.observable);
      }
    }
    return sb.toString();
  }
}
