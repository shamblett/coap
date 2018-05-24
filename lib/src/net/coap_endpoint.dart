/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// EndPoint encapsulates the stack that executes the CoAP protocol.
class CoapEndPoint implements CoapIEndPoint {
  static CoapILogger _log = new CoapLogManager("console").logger;

  CoapConfig _config;
  CoapIChannel _channel;
  CoapStack _coapStack;
  CoapIMessageDeliverer _deliverer;
  CoapIMatcher _matcher;
  InternetAddress _localEP;
  CoapIExecutor _executor;
}
