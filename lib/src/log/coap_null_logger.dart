/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Provides logging to null
class CoapNullLogger implements CoapILogger {
  /// Is debug enabled
  bool isDebugEnabled() {
    return false;
  }

  /// Is error enabled
  bool isErrorEnabled() {
    return false;
  }

  /// Is info enabled
  bool isInfoEnabled() {
    return false;
  }

  /// Is warning enabled
  bool isWarnEnabled() {
    return false;
  }

  /// Logs a debug message.
  void debug(String message) {}

  /// Logs an error message.
  void error(String message) {}

  /// Logs an info message.
  void info(String message) {}

  /// Logs a warning message.
  void warn(String message) {}
}
