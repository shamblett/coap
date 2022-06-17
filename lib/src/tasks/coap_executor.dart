/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/06/2018
 * Copyright :  S.Hamblett
 */

import 'package:executor/executor.dart';

import 'coap_iexecutor.dart';

/// Task executor
class CoapExecutor implements CoapIExecutor {
  /// The executor
  Executor executor = Executor(concurrency: 10);

  @override
  void start(final Action task) {
    executor.scheduleTask(task);
  }
}
