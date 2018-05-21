/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

class CoapMatcher implements CoapIMatcher {
  CoapMatcher(CoapConfig config) {
    _deduplicator = CoapDeduplicatorFactory.createDeduplicator(config);
    if (config.useRandomIDStart) _currentID = new Random().Next(1 << 16);
  }

  static CoapILogger _log = new CoapLogManager("console").logger;

  /// For all
  Map<CoapKeyId, CoapExchange> _exchangesByID =
      new Map<CoapKeyId, CoapExchange>();

  /// For outgoing
  Map<CoapKeyToken, CoapExchange> _exchangesByToken =
      new Map<CoapKeyToken, CoapExchange>();

  /// For blockwise
  Map<CoapKeyUri, CoapExchange> _ongoingExchanges =
      new Map<CoapKeyUri, CoapExchange>();

  int _running;
  int _currentID;
  CoapIDeduplicator _deduplicator;
}
