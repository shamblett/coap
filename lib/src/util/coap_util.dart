/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 26/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Cancellable asynchronous sleep support class
class CoapCancellableAsyncSleep {
  /// Timeout value in milliseconds
  CoapCancellableAsyncSleep(this._timeout);

  /// Millisecond timeout
  final int _timeout;

  /// Timeout
  int get timeout => _timeout;

  /// The completer
  final Completer<void> _completer = Completer<void>();

  /// The timer
  Timer _timer;

  /// Timer running flag
  bool _running = false;

  /// Running
  bool get isRunning => _running;

  /// Start the timer
  Future<void> sleep() {
    if (!_running) {
      _timer = Timer(Duration(milliseconds: _timeout), _timerCallback);
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
  static bool areSequenceEqualTo<T>(Iterable<T> first, Iterable<T> second,
      [collection.Equality<T> equality]) {
    final ie = collection.IterableEquality<T>(equality);
    if (ie != null) {
      return ie.equals(first, second);
    } else {
      return false;
    }
  }

  /// Finds the first matched item.
  /// Returns the item found, or null if none is matched.
  static T firstOrDefault<T>(Iterable<T> source, bool Function(T) condition) =>
      source.firstWhere(condition, orElse: () => null);

  /// Checks if matched item exists.
  /// Returns true if exists any matched item, otherwise false.
  static bool contains<T>(Iterable<T> source, bool Function(T) condition) {
    final dynamic res = source.takeWhile(condition);
    if (res.isNotEmpty) {
      return true;
    }
    return false;
  }

  /// Stringify a message.
  static String messageToString(CoapMessage msg) {
    final sb = StringBuffer();
    var kind = 'Message';
    if (msg.isRequest) {
      kind = 'Request';
    } else if (msg.isResponse) {
      kind = 'Response';
    }
    sb.writeln('==[ COAP $kind ]============================================');
    sb.writeln('ID     : ${msg.id}');
    sb.writeln('Type   : ${msg.type}');
    sb.writeln('Token  : ${msg.tokenString}');
    sb.writeln('Code   : ${msg.codeString}');
    if (msg.source != null) {
      sb.writeln('Source : ${msg.source}');
    }
    if (msg.destination != null) {
      sb.writeln('Dest : ${msg.destination}');
    }
    sb.writeln('Options: ${optionsToString(msg)}');
    sb.writeln('Payload: ${msg.payloadSize} Bytes');
    if (msg.payloadSize > 0 && CoapMediaType.isPrintable(msg.contentType)) {
      sb.writeln(
          '---------------------------------------------------------------');
      sb.writeln(msg.payloadString);
    }
    sb.writeln(
        '===============================================================');
    return sb.toString();
  }

  /// Stringify an iterable.
  static String iterableToString<T>(Iterable<T> source) {
    if ((source == null) || (source.isEmpty)) {
      return '';
    }
    final sb = StringBuffer();
    for (final item in source) {
      sb.write(item.toString());
      sb.write(',');
    }
    final ret = sb.toString();
    return ret.substring(0, ret.length - 1);
  }

  /// Stringify options in a message.
  static String optionsToString(CoapMessage msg) {
    if (msg == null) {
      return 'Message is null - no options';
    }
    final sb = StringBuffer();
    sb.writeln('If-Match : ${iterableToString(msg.ifMatches)}');
    sb.write('Uri Host : ');
    msg.hasOption(optionTypeUriHost)
        ? sb.writeln(msg.uriHost)
        : sb.writeln('None');
    sb.writeln('E-tags : ${iterableToString(msg.etags)}');
    msg.hasOption(optionTypeIfNoneMatch)
        ? sb.writeln('If-None Match : ${iterableToString(msg.ifNoneMatches)}')
        : sb.writeln('None');
    sb.write('Uri Port : ');
    if ((msg.uriPort != null) && (msg.uriPort > 0)) {
      sb.writeln(msg.uriPort);
    } else {
      sb.writeln('None');
    }
    sb.writeln('Location Paths: ${iterableToString(msg.locationPaths)}');
    sb.writeln('Uri Paths : ${msg.uriPathsString}');
    sb.write('Content-Type : ');
    sb.writeln(
        msg.contentType != CoapMediaType.undefined ? msg.contentType : 'None');
    sb.write('Max Age : ');
    msg.hasOption(optionTypeMaxAge)
        ? sb.writeln(msg.maxAge)
        : sb.writeln('None');
    sb.writeln('Uri Queries : ${iterableToString(msg.uriQueries)}');
    sb.write('Accept : ');
    sb.writeln(
        msg.contentType != CoapMediaType.undefined ? msg.accept : 'None');
    sb.writeln('Location Queries : ${iterableToString(msg.locationQueries)}');
    sb.write('Proxy Uri : ');
    msg.hasOption(optionTypeProxyUri)
        ? sb.writeln(msg.proxyUri)
        : sb.writeln('None');
    sb.write('Proxy Scheme : ');
    sb.writeln(msg.proxyScheme ?? 'None');
    sb.write('Block 1 : ');
    sb.writeln(msg.block1 ?? 'None');
    sb.write('Block 2 : ');
    sb.writeln(msg.block2 ?? 'None');
    sb.write('Observe : ');
    sb.writeln(msg.observe ?? 'None');
    sb.write('Size 1 : ');
    sb.writeln(msg.size1 ?? 'None');
    sb.write('Size 2 : ');
    sb.writeln(msg.size2 ?? 'None');
    return sb.toString();
  }

  /// Regex to check if a host name is an IP address
  static RegExp regIP = RegExp(
      r'(\\[[0-9a-f:]+\\]|[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3})',
      caseSensitive: false);

  /// Sleep function that allows asynchronous activity to continue.
  /// Time units are milliseconds
  static Future<void> asyncSleep(int milliseconds) =>
      Future<void>.delayed(Duration(milliseconds: milliseconds));

  /// Puts a value associated with a key into a Map,
  /// and returns the old value, or null if not exists.
  static TValue put<TKey, TValue>(
      Map<TKey, TValue> dic, TKey key, TValue value) {
    TValue old;
    if (dic.containsKey(key)) {
      old = dic[key];
    }
    dic[key] = value;
    return old;
  }

  /// Host lookup
  static Future<CoapInternetAddress> lookupHost(String host,
      InternetAddressType addressType, InternetAddress bindAddress) async {
    final completer = Completer<CoapInternetAddress>();
    final addresses = await InternetAddress.lookup(host, type: addressType);
    if (addresses != null && addresses.isNotEmpty) {
      final coapAddress = CoapInternetAddress(addressType, addresses[0]);
      coapAddress.bindAddress = bindAddress;
      completer.complete(coapAddress);
    } else {
      completer.complete(null);
    }
    return completer.future;
  }

  /// Resolved address logger
  static void logResolvedAddresses(List<InternetAddress> addresses) {
    if (addresses == null) {
      print('No resolved addresses');
      return;
    }
    for (final address in addresses) {
      print('Resolved address : $address');
    }
  }

  /// Time formatting for logging
  static String formatTime(DateTime time) => df.formatDate(time, <String>[
        df.yyyy,
        '-',
        df.mm,
        '-',
        df.dd,
        ' ',
        df.HH,
        ':',
        df.nn,
        ':',
        df.ss,
        '.',
        df.SSS
      ]);
}
