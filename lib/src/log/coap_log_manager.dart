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
    } else if (type == "file") {
      _logger = new CoapFileLogger(CoapConfig.inst.logFile);
    } else {
      _logger = new CoapNullLogger();
      setCommon = false;
    }

    // Logging common configuration
    if (setCommon) {
      logging.LoggerFactory.config[".*"].debugEnabled =
          CoapConfig.inst.logDebug;
      logging.LoggerFactory.config[".*"].errorEnabled =
          CoapConfig.inst.logError;
      logging.LoggerFactory.config[".*"].warnEnabled = CoapConfig.inst.logWarn;
      logging.LoggerFactory.config[".*"].infoEnabled = CoapConfig.inst.logInfo;
      logging.LoggerFactory.config[".*"].logFormat = "[%d] %c: %m";
    }
  }

  CoapILogger get logger => _logger;

  set logger(CoapILogger logger) => _logger = logger;
}
