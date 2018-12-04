/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Allows selection and management of logging for the coap library.
class CoapLogManager {
  /// Construction
  CoapLogManager(String type) {
    bool setCommon = true;
    if (type == 'console') {
      logger = CoapConsoleLogger();
    } else {
      logger = CoapNullLogger();
      setCommon = false;
    }

    // Logging common configuration
    if (setCommon) {
      if (CoapConfig.inst.logDebug) {
        logger.root.level = logging.Level.SEVERE;
      }
      if (CoapConfig.inst.logError) {
        logger.root.level = logging.Level.SHOUT;
      }
      if (CoapConfig.inst.logWarn) {
        logger.root.level = logging.Level.WARNING;
      }
      if (CoapConfig.inst.logInfo) {
        logger.root.level = logging.Level.INFO;
      }
    }
  }

  /// The logger
  CoapILogger logger;
}
