/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Provides logging to the console
class CoapConsoleLogger implements CoapILogger {
  static final logging.Logger _logger = new logging.Logger('ConsoleLogger');

  CoapConsoleLogger() {
    logging.Logger.root.level = logging.Level.ALL;
  }

  /// Root
  logging.Logger get root => logging.Logger.root;
  set root(logging.Logger root) {}

  /// Is debug enabled
  bool isDebugEnabled() {
    return _logger.level == logging.Level.SEVERE;
  }

  /// Is error enabled
  bool isErrorEnabled() {
    return _logger.level == logging.Level.SHOUT;
  }

  /// Is info enabled
  bool isInfoEnabled() {
    return _logger.level == logging.Level.INFO;
  }

  /// Is warning enabled
  bool isWarnEnabled() {
    return _logger.level == logging.Level.WARNING;
  }

  /// Logs a debug message.
  void debug(String message) {
    _logger.severe(_formatter(message));
  }

  /// Logs an error message.
  void error(String message) {
    _logger.shout(_formatter(message));
  }

  /// Logs an info message.
  void info(String message) {
    _logger.info(_formatter(message));
  }

  /// Logs a warning message.
  void warn(String message) {
    _logger.warning(_formatter(message));
  }

  /// Formatter
  String _formatter(String message) {
    final DateTime now = new DateTime.now();
    final String level = _logger.level.toString();
    return now.toString() + "  " + level + " >> ";
  }
}
