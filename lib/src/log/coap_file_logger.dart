/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Provides logging to a file
class FileLogger extends Ilogger {

  static final _logger = logger.LoggerFactory.getLoggerFor(FileLogger);

  FileLogger(String path) {
    logger.LoggerFactory.config["FileLogger"].appenders =
    [new logger.FileAppender(path)];
  }

  /// Is debug enabled
  bool isDebugEnabled() {
    return logger.LoggerFactory.config["FileLogger"].debugEnabled;
  }

  /// Is error enabled
  bool isErrorEnabled() {
    return logger.LoggerFactory.config["FileLogger"].errorEnabled;
  }

  /// Is info enabled
  bool isInfoEnabled() {
    return logger.LoggerFactory.config["FileLogger"].infoEnabled;
  }

  /// Is warning enabled
  bool isWarnEnabled() {
    return logger.LoggerFactory.config["FileLogger"].warnEnabled;
  }

  /// Logs a debug message.
  void debug(String message) {
    _logger.debug(message);
  }

  /// Logs an error message.
  void error(String message) {
    _logger.error(message);
  }

  /// Logs an info message.
  void info(String message) {
    _logger.info(message);
  }

  /// Logs a warning message.
  void warn(String message) {
    _logger.warn(message);
  }
}