/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// This class describes the functionality of a CoAP remote resource.
class CoapRemoteResource extends CoapEndpointResource {
  CoapRemoteResource(String resourceIdentifier) : super(resourceIdentifier);

  CoapRemoteResource.hide(String resourceIdentifier, bool hidden)
      : super.hide(resourceIdentifier, hidden: hidden);

  static CoapRemoteResource newRoot(String linkFormat) {
    return CoapLinkFormat.deserialize(linkFormat);
  }

  /// Creates a resource instance with proper subtype.
  @override
  CoapEndpointResource createInstance(String name) {
    return new CoapRemoteResource(name);
  }

  @override
  void doCreateSubResource(CoapRequest request, String newIdentifier) {}
}
