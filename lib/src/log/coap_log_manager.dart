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
    return _singleton ??= CoapLogManager._internal(_type);
  }

  CoapLogManager._internal([String type]) {
    var setCommon = true;
    if (type == null || type == 'console') {
      logger = CoapConsoleLogger();
    } else {
      logger = CoapNullLogger();
      setCommon = false;
    }
    // Logging common configuration
    if (setCommon) {
      if (DefaultCoapConfig.inst.logDebug) {
        // Debug maps to severe
        logger.level = logging.Level.SEVERE;
      }
      if (DefaultCoapConfig.inst.logError) {
        // Error maps to shout, always sets
        logger.level = logging.Level.SHOUT;
      }
      if (DefaultCoapConfig.inst.logWarn) {
        // Warning is warning
        logger.level = logging.Level.WARNING;
      }
      if (DefaultCoapConfig.inst.logInfo) {
        // Info is info
        logger.level = logging.Level.INFO;
      }
    }
  }

  /// Logger type
  static String _type;

  static CoapLogManager _singleton;

  /// The logger
  CoapILogger logger;

  /// Destroys the instance, the log manager must be reconstructed before
  /// use
  void destroy() => _singleton = null;
}
