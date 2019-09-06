/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Provides logging to null
class CoapNullLogger implements CoapILogger {
  static final logging.Logger _logger = logging.Logger('NullLogger');

  @override
  logging.Logger get root => null;

  @override
  set root(logging.Logger root) {}

  @override
  logging.Level get level => _logger.level;

  @override
  set level(logging.Level level) => _logger.level = level;

  @override
  String get lastMessage => null;

  @override
  set lastMessage(String message) {}

  @override
  bool isDebugEnabled() => false;

  @override
  bool isErrorEnabled() => false;

  @override
  bool isInfoEnabled() => false;

  @override
  bool isWarnEnabled() => false;

  @override
  void debug(String message) {}

  @override
  void error(String message) {}

  @override
  void info(String message) {}

  @override
  void warn(String message) {}
}
