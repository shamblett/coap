/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Allows selection and management of logging for the coap library.
class LogManager {
  static Ilogger _logger;

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
      logging.LoggerFactory.config[".*"].debugEnabled =
          CoapConfig.inst.logDebug;
      logging.LoggerFactory.config[".*"].errorEnabled =
          CoapConfig.inst.logError;
      logging.LoggerFactory.config[".*"].warnEnabled = CoapConfig.inst.logWarn;
      logging.LoggerFactory.config[".*"].infoEnabled = CoapConfig.inst.logInfo;
      logging.LoggerFactory.config[".*"].logFormat = "[%d] %c %n:%x %n";
    }
  }

  Ilogger get logger => _logger;

  set logger(Ilogger logger) => _logger = logger;
}
