/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Allows selection and management of logging for the coap library.
class CoapLogManager {
  static CoapILogger _logger;

  CoapLogManager(String type) {
    bool setCommon = true;
    if (type == "console") {
      _logger = new CoapConsoleLogger();
    } else {
      _logger = new CoapNullLogger();
      setCommon = false;
    }

    // Logging common configuration
    if (setCommon) {
      if (CoapConfig.inst.logDebug) {
        _logger.root.level = logging.Level.SEVERE;
      }
      if (CoapConfig.inst.logError) {
        _logger.root.level = logging.Level.SHOUT;
      }
      if (CoapConfig.inst.logWarn) {
        _logger.root.level = logging.Level.WARNING;
      }
      if (CoapConfig.inst.logInfo) {
        _logger.root.level = logging.Level.INFO;
      }
    }
  }

  CoapILogger get logger => _logger;

  set logger(CoapILogger logger) => _logger = logger;
}
