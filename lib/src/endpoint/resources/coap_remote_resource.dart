/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

import '../../coap_link_format.dart';
import '../../coap_request.dart';
import 'coap_endpoint_resource.dart';

/// This class describes the functionality of a CoAP remote resource.
class CoapRemoteResource extends CoapEndpointResource {
  /// Construction
  CoapRemoteResource(String resourceIdentifier) : super(resourceIdentifier);

  /// Hidden
  CoapRemoteResource.hide(String resourceIdentifier, {bool hidden = true})
      : super.hide(resourceIdentifier, hidden: hidden);

  /// New root
  static CoapRemoteResource newRoot(String linkFormat) =>
      CoapLinkFormat.deserialize(linkFormat);

  /// Creates a resource instance with proper subtype.
  @override
  CoapEndpointResource createInstance(String name) => CoapRemoteResource(name);

  @override
  void doCreateSubResource(CoapRequest request, String newIdentifier) {}
}
