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

  static CoapRemoteResource newRoot(String linkFormat) {
    return CoapLinkFormat.deserialize(linkFormat);
  }

  /// Creates a resouce instance with proper subtype.
  CoapEndpointResource createInstance(String name) {
    return new CoapRemoteResource(name);
  }

  void doCreateSubResource(CoapRequest request, String newIdentifier) {}
}
