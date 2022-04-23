/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 26/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Cancellable asynchronous sleep support class
class CoapCancellableAsyncSleep {
  CoapCancellableAsyncSleep(this._timeout);

  final Duration _timeout;

  /// Timeout
  Duration get timeout => _timeout;

  /// The completer
  final Completer<void> _completer = Completer<void>();

  /// The timer
  late Timer _timer;

  /// Timer running flag
  bool _running = false;

  /// Running
  bool get isRunning => _running;

  /// Start the timer
  Future<void> sleep() {
    if (!_running) {
      _timer = Timer(_timeout, _timerCallback);
      _running = true;
    }
    return _completer.future;
  }

  /// Cancel the timer
  void cancel() {
    if (_running) {
      _timer.cancel();
      _running = false;
      _completer.complete();
    }
  }

  /// The timer callback
  void _timerCallback() {
    _running = false;
    _completer.complete();
  }
}

/// Utility methods
class CoapUtil {
  /// Insertion sort, to make the options list stably ordered.
  static void insertionSort<T>(List<T> list, Comparator<T> comparison) {
    collection.insertionSort(list, compare: comparison);
  }

  /// Checks if all items in both of the two enumerables are equal.
  static bool areSequenceEqualTo<T>(Iterable<T>? first, Iterable<T>? second,
      [collection.Equality<T>? equality]) {
    final ie = collection.IterableEquality<T>(equality!);
    return ie.equals(first, second);
  }

  /// Finds the first matched item.
  /// Returns the item found, or null if none is matched.
  static T? firstOrDefault<T>(Iterable<T> source, bool Function(T) condition) =>
      source.firstWhereOrNull(condition);

  /// Checks if matched item exists.
  /// Returns true if exists any matched item, otherwise false.
  static bool contains<T>(Iterable<T> source, bool Function(T) condition) =>
      source.takeWhile(condition).isNotEmpty;

  /// Stringify an iterable.
  static String iterableToString<T>(Iterable<T> source) {
    final sb = StringBuffer();
    for (final item in source) {
      sb.write(item.toString());
      if (item != source.last) {
        sb.write(',');
      }
    }
    return sb.toString();
  }

  /// Stringify options in a message.
  static String optionsToString(CoapMessage msg) {
    final sb = StringBuffer();
    sb.writeln('[');
    sb.write(optionString('If-Match', msg.ifMatches));
    sb.write(optionString('Uri Host', msg.uriHost));
    sb.write(optionString('E-tags', msg.etags));
    sb.write(optionString('If-None Match', msg.ifNoneMatches));
    sb.write(optionString('Uri Port', msg.uriPort > 0 ? msg.uriPort : null));
    sb.write(optionString('Location Paths', msg.locationPaths));
    sb.write(optionString('Uri Paths', msg.uriPathsString));
    sb.write(optionString('Content-Type', CoapMediaType.name(msg.contentType)));
    sb.write(optionString('Max Age', msg.maxAge));
    sb.write(optionString('Uri Queries', msg.uriQueries));
    if (msg.accept != CoapMediaType.undefined) {
      sb.write(optionString('Accept', CoapMediaType.name(msg.accept)));
    }
    sb.write(optionString('Location Queries', msg.locationQueries));
    sb.write(optionString('Proxy Uri', msg.proxyUri));
    sb.write(optionString('Proxy Scheme', msg.proxyScheme));
    sb.write(optionString('Block 1', msg.block1));
    sb.write(optionString('Block 2', msg.block2));
    sb.write(optionString('Observe', msg.observe));
    sb.write(optionString('Size 1', msg.size1));
    sb.write(optionString('Size 2', msg.size2));
    sb.write(']');
    return sb.toString();
  }

  static String optionString(String name, Object? value) {
    if (value == null) {
      return '';
    }
    var str = '';
    if (value is Iterable) {
      str = iterableToString(value);
    } else {
      str = value.toString();
    }
    return str != '' ? '  $name: $str,\n' : '';
  }

  /// Regex to check if a host name is an IP address
  static RegExp regIP = RegExp(
      r'(\\[[0-9a-f:]+\\]|[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3})',
      caseSensitive: false);

  /// Host lookup, does not use the resolver if the host is an IP address.
  static Future<CoapInternetAddress?> lookupHost(String host,
      InternetAddressType addressType, InternetAddress? bindAddress) async {
    final completer = Completer<CoapInternetAddress?>();
    final parsedAddress = InternetAddress.tryParse(host);
    if (parsedAddress != null) {
      final coapAddress =
          CoapInternetAddress(parsedAddress.type, parsedAddress, bindAddress);
      completer.complete(coapAddress);
      return completer.future;
    }

    final addresses = await InternetAddress.lookup(host, type: addressType);
    if (addresses.isNotEmpty) {
      final coapAddress =
          CoapInternetAddress(addressType, addresses[0], bindAddress);
      completer.complete(coapAddress);
    } else {
      completer.complete(null);
    }
    return completer.future;
  }
}
