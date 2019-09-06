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
  factory CoapLogManager([String type]) {
    _type = type;
    return _singleton;
  }

  CoapLogManager._internal([String type]) {
    bool setCommon = true;
    if (type == null || type == 'console') {
      logger = CoapConsoleLogger();
    } else {
      logger = CoapNullLogger();
      setCommon = false;
    }
    // Logging common configuration
    if (setCommon) {
      if (CoapConfig.inst.logDebug) {
        if (logger.level >= logging.Level.INFO) {
          logger.level = logging.Level.SEVERE;
        }
      }
      if (CoapConfig.inst.logError) {
        if (logger.level < logging.Level.SEVERE) {
          logger.root.level = logging.Level.SHOUT;
        }
      }
      if (CoapConfig.inst.logWarn) {
        if (logger.root.level < logging.Level.SHOUT) {
          logger.root.level = logging.Level.WARNING;
        }
      }
      if (CoapConfig.inst.logInfo) {
        if (logger.root.level < logging.Level.WARNING) {
          logger.root.level = logging.Level.INFO;
        }
      }
    }
  }

  /// Logger type
  static String _type;

  static final CoapLogManager _singleton = CoapLogManager._internal(_type);

  /// The logger
  CoapILogger logger;
}
