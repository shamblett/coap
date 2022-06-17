/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

import 'coap_link_format.dart';
import 'resources/coap_resource_attributes.dart';

/// This class can be used to programmatically browse a remote CoAP endoint.
class CoapWebLink extends Comparable<CoapWebLink> {
  /// Instantiates.
  CoapWebLink(this._uri);

  final String _uri;

  /// The URI
  String get uri => _uri;
  final CoapResourceAttributes _attributes = CoapResourceAttributes();

  /// Attributes
  CoapResourceAttributes get attributes => _attributes;

  @override
  int compareTo(final CoapWebLink other) => _uri.compareTo(other._uri);

  @override
  String toString() {
    final sb = StringBuffer('<$_uri> ');
    if (_attributes.isNotEmpty) {
      if (_attributes.contains(CoapLinkFormat.title)) {
        sb
          ..write('\n\t${CoapLinkFormat.title}:\t')
          ..write(_attributes.title);
      }
      if (_attributes.contains(CoapLinkFormat.resourceType)) {
        sb
          ..write('\n\t${CoapLinkFormat.resourceType}:\t')
          ..write(_attributes.getResourceTypes());
      }
      if (_attributes.contains(CoapLinkFormat.interfaceDescription)) {
        sb
          ..write('\n\t${CoapLinkFormat.interfaceDescription}:\t')
          ..write(_attributes.getInterfaceDescriptions());
      }
      if (_attributes.contains(CoapLinkFormat.contentType)) {
        sb
          ..write('\n\t${CoapLinkFormat.contentType}:\t')
          ..write(_attributes.getContentTypes());
      }
      if (_attributes.contains(CoapLinkFormat.maxSizeEstimate)) {
        sb
          ..write('\n\t${CoapLinkFormat.maxSizeEstimate}:\t')
          ..write(_attributes.maximumSizeEstimate);
      }
      if (_attributes.observable != null) {
        sb.write('\n\t${CoapLinkFormat.observable}');
      }
    }
    return sb.toString();
  }
}
