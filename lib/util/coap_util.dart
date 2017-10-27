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

  /// Finds the first matched item.
  /// Returns the item found, or null if none is matched.
  static T firstOrDefault<T>(Iterable<T> source, bool condition(T element)) {
    return source.firstWhere(condition, orElse: () => null);
  }

  /// Checks if matched item exists.
  /// Returns true if exists any matched item, otherwise false.
  static bool contains<T>(Iterable<T> source, bool condition(T element)) {
    final res = source.takeWhile(condition);
    if (res.isNotEmpty) {
      return true;
    }
    return false;
  }

  /// Stringify a message.
  static String messageToString(Message msg) {
    final StringBuffer sb = new StringBuffer();
    String kind = "Message";
    String code = "Code";
    if (msg.isRequest) {
      kind = "Request";
      code = "Method";
    } else if (msg.isResponse) {
      kind = "Response";
      code = "Status";
    }
    sb.writeln("==[ COAP $kind ]============================================");
    sb.writeln("ID     : ${msg.id}");
    sb.writeln("Type   : ${msg.type}");
    sb.writeln("Token  : ${msg.tokenString}");
    sb.writeln("Code   : ${msg.codeString}");
    if (msg.source != null) {
      sb.writeln("Source : ${msg.source}");
    }
    if (msg.destination != null) {
      sb.writeln("Dest : ${msg.destination}");
    }
    sb.writeln("Options: ${ optionsToString(msg)}");
    sb.writeln("Payload: ${msg.payloadSize} Bytes");
    if (msg.payloadSize > 0 && MediaType.isPrintable(msg.contentType)) {
      sb.writeln(
          "---------------------------------------------------------------");
      sb.writeln(msg.payloadString);
    }
    sb.writeln(
        "===============================================================");
    return sb.toString();
  }

  /// Stringify options in a message.
  static String optionsToString(Message msg) {
    return "";
  }
}
