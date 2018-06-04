/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 04/06/2018
 * Copyright :  S.Hamblett
 */

part of coap;

class CoapExecutor implements CoapIExecutor {
  tasking.Executor executor = new tasking.Executor(concurrency: 10);

  /// Starts a task.
  void start(Action task) {
    executor.scheduleTask(() {
      task;
    });
  }
}
