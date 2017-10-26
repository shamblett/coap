/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 26/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Utility methods
class Util {
  /// Insertion sort, to make the options list stably ordered.
  static void insertionSort<T>(List<T> list, Comparator<T> comparison) {
    list.sort(comparison);
  }

  /// Checks if all items in both of the two enumerables are equal.
  public static

  Boolean AreSequenceEqualTo<T>(IEnumerable<T> first, IEnumerable<T> second) {
    return AreSequenceEqualTo<T>(first, second, null);
  }

  /// Stringify options in a message.
  static String optionsToString(Message msg) {
    return "";
  }
}
