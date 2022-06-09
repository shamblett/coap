// ignore_for_file: one_member_abstracts

/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 08/04/2018
 * Copyright :  S.Hamblett
 */

typedef Action = void Function();
typedef ActionGeneric<T> = void Function(T);

/// Provides methods to execute tasks.
abstract class CoapIExecutor {
  /// Starts a task.
  void start(final Action task);
}
