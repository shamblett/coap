/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 05/06/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Provides convenient methods for accessing CoAP resources.
class CoapClient {
  /// Instantiates.
  CoapClient(Uri inuri, CoapConfig config) {
    uri = inuri;
    _config = config;
  }

  static CoapILogger _log = new CoapLogManager("console").logger;
  static Iterable<CoapWebLink> _emptyLinks = [new CoapWebLink("")];
  Uri uri;
  CoapConfig _config;
  CoapIEndPoint endpoint;
  int _type = CoapMessageType.con;
  int _blockwise;
  int timeout = 32767;

  /// Let the client use Confirmable requests.
  CoapClient useCONs() {
    _type = CoapMessageType.con;
    return this;
  }

  /// Let the client use early negotiation for the blocksize
  /// (16, 32, 64, 128, 256, 512, or 1024). Other values will
  /// be matched to the closest logarithm dualis.
  CoapClient useEarlyNegotiation(int size) {
    _blockwise = size;
    return this;
  }

  /// Let the client use late negotiation for the block size (default).
  CoapClient useLateNegotiation() {
    _blockwise = 0;
    return this;
  }

  /// Performs a CoAP ping.
  bool ping() {
    return doPing(timeout);
  }

  /// Performs a CoAP ping and gives up after the given number of milliseconds.
  bool doPing(int timeout) {
    try {
      CoapRequest request = new CoapRequest(CoapCode.empty);
      request.token = CoapConstants.emptyToken;
      request.uri = uri;
      request.send().waitForResponse(timeout);
      return request.isRejected;
    } catch (e) {
      _log.warn("Exception raise pinging: $e");
    }
    return false;
  }

  /// Discovers remote resources.
  Iterable<CoapWebLink> discover() {
    return doDiscover(null);
  }

  /// Discovers remote resources.
  Iterable<CoapWebLink> doDiscover(String query) {
    CoapRequest discover = Prepare(CoapRequest.newGet());
    discover.clearUriPath().clearUriQuery().uriPath =
        CoapConstants.defaultWellKnownURI;
    if (query != null && query.isNotEmpty) {
      discover.uriQuery = query;
    }
    CoapResponse links = discover.send().waitForResponse(timeout);
    if (links == null) {
      // If no response, return null (e.g., timeout)
      return null;
    } else if (links.contentFormat != CoapMediaType.applicationLinkFormat) {
      return _emptyLinks;
    } else
      return CoapLinkFormat.parse(links.payloadString);
  }
}
