/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 26/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Utility methods
class CoapUtil {
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
  static String messageToString(CoapMessage msg) {
    final StringBuffer sb = new StringBuffer();
    String kind = "Message";
    if (msg.isRequest) {
      kind = "Request";
    } else if (msg.isResponse) {
      kind = "Response";
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
    sb.writeln("Options: ${optionsToString(msg)}");
    sb.writeln("Payload: ${msg.payloadSize} Bytes");
    if (msg.payloadSize > 0 && CoapMediaType.isPrintable(msg.contentType)) {
      sb.writeln(
          "---------------------------------------------------------------");
      sb.writeln(msg.payloadString);
    }
    sb.writeln(
        "===============================================================");
    return sb.toString();
  }

  /// Stringify an iterable.
  static String iterableToString<T>(Iterable<T> source) {
    if ((source == null) || (source.isEmpty)) {
      return "";
    }
    final StringBuffer sb = new StringBuffer();
    for (T item in source) {
      sb.write(item.toString());
      sb.write(",");
    }
    final String ret = sb.toString();
    return ret.substring(0, ret.length - 2);
  }

  /// Stringify options in a message.
  static String optionsToString(CoapMessage msg) {
    if (msg == null) {
      return "Message is null - no options";
    }
    final StringBuffer sb = new StringBuffer();
    sb.writeln("If-Match : " + iterableToString(msg.ifMatches) ?? "None");
    sb.write("Uri Host : ");
    msg.hasOption(optionTypeUriHost) ? sb.writeln(msg.uriHost) : "None";
    sb.writeln("E-tags : " + iterableToString(msg.etags) ?? "None");
    msg.hasOption(optionTypeIfNoneMatch) ? sb.writeln(msg.ifNoneMatch) : "None";
    sb.write("Uri Port : ");
    if ((msg.uriPort != null) && (msg.uriPort > 0)) {
      sb.writeln(msg.uriPort);
    } else {
      sb.writeln("None");
    }
    sb.writeln(
        "Location Paths: " + iterableToString(msg.locationPaths) ?? "None");
    sb.writeln("Uri Paths : " + iterableToString(msg.uriPaths) ?? "None");
    sb.write("Content-Type : ");
    sb.writeln(
        msg.contentType != CoapMediaType.undefined ? msg.contentType : "None");
    sb.write("Max Age : ");
    msg.hasOption(optionTypeMaxAge) ? sb.writeln(msg.maxAge) : "None";
    sb.writeln("Uri Queries : " + iterableToString(msg.uriQueries) ?? "None");
    sb.write("Accept : ");
    sb.writeln(
        msg.contentType != CoapMediaType.undefined ? msg.accept : "None");
    sb.writeln("Location Queries : " + iterableToString(msg.locationQueries) ??
        "None");
    sb.write("Proxy Uri : ");
    msg.hasOption(optionTypeProxyUri) ? sb.writeln(msg.proxyUri) : "None";
    sb.write("Proxy Scheme : ");
    sb.writeln(msg.proxyScheme ?? "None");
    sb.write("Block 1 : ");
    sb.writeln(msg.block1 ?? "None");
    sb.write("Block 2 : ");
    sb.writeln(msg.block2 ?? "None");
    sb.write("Observe : ");
    sb.writeln(msg.observe ?? "None");
    sb.write("Size 1 : ");
    sb.writeln(msg.size1 ?? "None");
    sb.write("Size 2 : ");
    sb.writeln(msg.size2 ?? "None");
    return sb.toString();
  }
}
