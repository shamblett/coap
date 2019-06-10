/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/06/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Task executor
class CoapExecutor implements CoapIExecutor {
  /// The executor
  tasking.Executor executor = tasking.Executor(concurrency: 10);

  @override
  void start(Action task) {
    print('SJH - trace - start');
    executor.scheduleTask(() {
      task();
    });
  }
}
