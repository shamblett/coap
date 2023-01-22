/// Caches entries of type [T], using values of type [S] as the cache key.
class Cache<S, T> {
  /// Generate a new [Cache] that uses the given [hashFunction] for determining
  /// the eventual cache key for the chosen key type [S].
  ///
  /// If no [hashFunction] is passend, then [Object.hashCode] will be used
  /// instead.
  Cache([final int Function(S cacheKey)? hashFunction])
      : _hashFunction = hashFunction ?? _defaultHashFunction;

  final _cache = <int, _CacheEntry<T>>{};

  final int Function(S cacheKey) _hashFunction;

  bool _isFresh(final _CacheEntry<T> cacheEntry) {
    final cacheValidity = cacheEntry.timeToLive;

    if (cacheValidity == null || cacheValidity == Duration.zero) {
      return true;
    }

    final timeInCache = DateTime.now().difference(cacheEntry.timeStamp);

    return timeInCache > cacheValidity;
  }

  /// Retrieves a value of type [T] from the cache, if present, using a given
  /// [key].
  ///
  /// If the cache entry was created with a specified time-to-live, the entry
  /// will be cleaned up if the time-to-live period has expired.
  /// In this case, the method will return [Null].
  T? retrieve(final S key) {
    final cacheValue = _cache[_hashFunction(key)];

    if (cacheValue == null) {
      return null;
    }

    if (_isFresh(cacheValue)) {
      return cacheValue.value;
    }

    _cache.remove(key);
    return null;
  }

  static int _defaultHashFunction<S>(final S key) => key.hashCode;

  /// Removes an entry from the cache, if present, using the given [key].
  void remove(final S key) => _cache.remove(_cache[_hashFunction(key)]);

  /// Adds a new [value] with an optional [timeToLive] to the cache, using
  /// the given [key].
  ///
  /// If the key should already be present, it will be overridden.
  void save(final S key, final T value, [final Duration? timeToLive]) =>
      _cache[_hashFunction(key)] = _CacheEntry(value, timeToLive);
}

class _CacheEntry<T> {
  _CacheEntry(this.value, this.timeToLive) : timeStamp = DateTime.now();

  final T value;

  final DateTime timeStamp;

  final Duration? timeToLive;
}
