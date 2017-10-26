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
    collection.insertionSort(list, compare: comparison);
  }

  /// Checks if all items in both of the two enumerables are equal.
  static bool areSequenceEqualTo<T>(Iterable<T> first, Iterable<T> second,
      [collection.Equality<T> equality = const collection.DefaultEquality()]) {
    final collection.IterableEquality ie =
    new collection.IterableEquality(equality);
    return ie.equals(first, second);
  }

  /// Stringify options in a message.
  static String optionsToString(Message msg) {
    return "";
  }
}
