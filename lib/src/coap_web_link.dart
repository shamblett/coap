/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

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
  int compareTo(dynamic other) {
    if (other == null) {
      throw ArgumentError.notNull('CoapWebLink::other');
    }
    return _uri.compareTo(other._uri);
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write('<$_uri> ');
    if (_attributes.isNotEmpty) {
      if (_attributes.contains(CoapLinkFormat.title)) {
        sb.write('\n\t${CoapLinkFormat.title}:\t');
        sb.write(_attributes.title);
      }
      if (_attributes.contains(CoapLinkFormat.resourceType)) {
        sb.write('\n\t${CoapLinkFormat.resourceType}:\t');
        sb.write(_attributes.getResourceTypes());
      }
      if (_attributes.contains(CoapLinkFormat.interfaceDescription)) {
        sb.write('\n\t${CoapLinkFormat.interfaceDescription}:\t');
        sb.write(_attributes.getInterfaceDescriptions());
      }
      if (_attributes.contains(CoapLinkFormat.contentType)) {
        sb.write('\n\t${CoapLinkFormat.contentType}:\t');
        sb.write(_attributes.getContentTypes());
      }
      if (_attributes.contains(CoapLinkFormat.maxSizeEstimate)) {
        sb.write('\n\t${CoapLinkFormat.maxSizeEstimate}:\t');
        sb.write(_attributes.maximumSizeEstimate);
      }
      if (_attributes.observable != null) {
        sb.write('\n\t${CoapLinkFormat.observable}');
      }
    }
    return sb.toString();
  }
}
