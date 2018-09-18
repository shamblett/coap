/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 08/04/2018
 * Copyright :  S.Hamblett
 */

part of coap;

typedef void Action();
typedef void ActionGeneric<T>(T v);

/// Provides methods to execute tasks.
abstract class CoapIExecutor {
  /// Starts a task.
  void start(Action task);
}
