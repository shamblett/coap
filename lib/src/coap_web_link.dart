/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// This class can be used to programmatically browse a remote CoAP endoint.
class CoapWebLink extends Comparable {
  /// Instantiates.
  CoapWebLink(String uri) {
    _uri = uri;
  }

  String _uri;

  String get uri => _uri;
  CoapResourceAttributes _attributes = new CoapResourceAttributes();

  CoapResourceAttributes get attributes => _attributes;

  int compareTo(dynamic other) {
    if (other == null) {
      throw new ArgumentError.notNull("CoapWebLink::other");
    }
    return _uri.compareTo((other as CoapWebLink)._uri);
  }

  String toString() {
    final StringBuffer sb = new StringBuffer();
    sb.write('<');
    sb.write(_uri);
    sb.write('>');
    sb.write(' ');
    sb.write(_attributes.title);
    if (_attributes.contains(CoapLinkFormat.resourceType)) {
      sb.write("\n\t");
      sb.write(CoapLinkFormat.resourceType);
      sb.write(":\t");
      sb.write(_attributes.getResourceTypes());
    }
    if (_attributes.contains(CoapLinkFormat.interfaceDescription)) {
      sb.write("\n\t");
      sb.write(CoapLinkFormat.interfaceDescription);
      sb.write(":\t");
      sb.write(_attributes.getInterfaceDescriptions());
    }
    if (_attributes.contains(CoapLinkFormat.contentType)) {
      sb.write("\n\t");
      sb.write(CoapLinkFormat.contentType);
      sb.write(":\t");
      sb.write(_attributes.getContentTypes());
    }
    if (_attributes.contains(CoapLinkFormat.maxSizeEstimate)) {
      sb.write("\n\t");
      sb.write(CoapLinkFormat.maxSizeEstimate);
      sb.write(":\t");
      sb.write(_attributes.maximumSizeEstimate);
    }
    if (_attributes.observable) {
      sb.write("\n\t");
      sb.write(CoapLinkFormat.observable);
    }
    return sb.toString();
  }
}
