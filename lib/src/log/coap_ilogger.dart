/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Provides methods to log messages.
abstract class CoapILogger {
  /// Is debug enabled
  bool isDebugEnabled();

  /// Is error enabled
  bool isErrorEnabled();

  /// Is info enabled
  bool isInfoEnabled();

  /// Is warning enabled
  bool isWarnEnabled();

  /// Logs a debug message.
  void debug(String message);

  /// Logs an error message.
  void error(String message);

  /// Logs an info message.
  void info(String message);

  /// Logs a warning message.
  void warn(String message);
}
