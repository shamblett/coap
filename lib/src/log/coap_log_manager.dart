/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Allows selection and management of logging or the coap library.
class LogManager {

  Ilogger _logger;

  LogManager(String type, [String path]) {
    bool setCommon = true;
    if (type == "console") {
      _logger = new ConsoleLogger();
    } else if (type == "file") {
      _logger = new FileLogger(path);
    } else {
      _logger = new NullLogger();
      setCommon = false;
    }

    // Logging common configuration
    if (setCommon) {
      logger.LoggerFactory.config[".*"].debugEnabled = CoapConfig.logDebug;
      logger.LoggerFactory.config[".*"].errorEnabled = CoapConfig.logError;
      logger.LoggerFactory.config[".*"].warnEnabled = CoapConfig.logWarn;
      logger.LoggerFactory.config[".*"].infoEnabled = CoapConfig.logInfo;
    }
  }

}