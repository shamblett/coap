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
  CoapRemoteResource(super.resourceIdentifier);

  /// Hidden
  CoapRemoteResource.hide(super.resourceIdentifier, {final super.hidden})
      : super.hide();

  /// New root
  static CoapRemoteResource newRoot(final String linkFormat) =>
      CoapLinkFormat.deserialize(linkFormat);

  /// Creates a resource instance with proper subtype.
  @override
  CoapEndpointResource createInstance(final String name) =>
      CoapRemoteResource(name);

  @override
  void doCreateSubResource(
    final CoapRequest request,
    final String newIdentifier,
  ) {}
}
