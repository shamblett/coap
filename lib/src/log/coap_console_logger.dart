/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Provides logging to the console
class CoapConsoleLogger implements CoapILogger {
  /// Construction
  CoapConsoleLogger() {
    logging.hierarchicalLoggingEnabled = true;
    _logger.level = logging.Level.OFF;
    root.onRecord.listen((logging.LogRecord rec) {
      print('${CoapUtil.formatTime(rec.time)}: '
          '${rec.level.name}: ${rec.message}');
    });
  }

  static final logging.Logger _logger = logging.Logger('ConsoleLogger');

  @override
  logging.Logger get root => logging.Logger.root;

  @override
  set root(logging.Logger root) {}

  @override
  logging.Level get level => _logger.level;

  @override
  set level(logging.Level level) => _logger.level = level;

  /// Last message
  String _lastMessage;

  @override
  String get lastMessage => _lastMessage;

  @override
  set lastMessage(String message) {}

  @override
  bool isDebugEnabled() => _logger.level.value <= logging.Level.SEVERE.value;

  @override
  bool isErrorEnabled() => _logger.level.value <= logging.Level.SHOUT.value;

  @override
  bool isInfoEnabled() => _logger.level.value <= logging.Level.INFO.value;

  @override
  bool isWarnEnabled() => _logger.level.value <= logging.Level.WARNING.value;

  @override
  void debug(String message) {
    _logger.severe(_formatter(message));
  }

  @override
  void error(String message) {
    _logger.shout(_formatter(message));
  }

  @override
  void info(String message) {
    _logger.info(_formatter(message));
  }

  @override
  void warn(String message) {
    _logger.warning(_formatter(message));
  }

  /// Formatter
  String _formatter(String message) => _lastMessage = '>> $message';
}
