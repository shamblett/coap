/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

class CoapObserveLayer extends CoapAbstractLayer {
  /// Constructs a new observe layer.
  CoapObserveLayer(CoapConfig config) {
    _backoff = config.notificationReregistrationBackoff;
  }

  static CoapILogger _log = new CoapLogManager("console").logger;
  static String reregistrationContextKey = "ReregistrationContext";

  /// Additional time to wait until re-registration
  int _backoff;
}
