/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

import 'coap_link_format.dart';
import 'resources/coap_resource_attributes.dart';

/// This class can be used to programmatically browse a remote CoAP endoint.
class CoapWebLink implements Comparable<CoapWebLink> {
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
      for (final linkFormatParameter in LinkFormatParameter.values) {
        final key = linkFormatParameter.short;
        if (_attributes.contains(key)) {
          sb
            ..write('\n\t$key:\t')
            ..write(_attributes.getValues(key));
        }
      }
      if (_attributes.observable != null) {
        sb.write('\n\t${LinkFormatParameter.observable}');
      }
    }
    return sb.toString();
  }
}
