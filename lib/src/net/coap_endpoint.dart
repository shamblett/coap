/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// EndPoint encapsulates the stack that executes the CoAP protocol.
class CoapEndPoint extends Object
    with events.EventDetector
    implements CoapIEndPoint {

  /// Instantiates a new endpoint with the
  /// specified channel and configuration.
  CoapEndPoint(CoapIChannel channel, CoapConfig config) {
    _config = config;
    _channel = channel;
    _matcher = new CoapMatcher(config);
    _coapStack = new CoapStack(config);
    listen(_channel, CoapDataReceivedEvent, _receiveData);
  }

  static CoapILogger _log = new CoapLogManager("console").logger;

  CoapConfig _config;
  CoapIChannel _channel;
  CoapStack _coapStack;
  CoapIMessageDeliverer _deliverer;
  CoapIMatcher _matcher;
  InternetAddress _localEP;
  CoapIExecutor _executor;


  void _receiveData(events.Event<CoapDataReceivedEvent> event) {
    //TODO
  }

}
