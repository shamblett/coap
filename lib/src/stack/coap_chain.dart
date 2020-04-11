/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

typedef TEqualsFunc = bool Function<TFilter>(TFilter a, TFilter b);
typedef TEntryFactoryFunc
    = CoapEntry<dynamic, dynamic> Function<TChain, TFilter>(
        TChain a,
        CoapEntry<dynamic, dynamic> b,
        CoapEntry<dynamic, dynamic> c,
        String d,
        TFilter e);
typedef TNextFilterFactory<TNextFilter, TFilter> = TNextFilter Function(
    TFilter v);
typedef TFilterFactory<TFilter> = TFilter Function();

/// Represents a chain of filters.
abstract class CoapIChain<TFilter, TNextFilter> {
  /// Gets the entry with the specified name in this chain.
  CoapIEntry<TFilter, TNextFilter> getEntryByName(String name);

  /// Gets the entry with the specified filter in this chain.
  CoapIEntry<TFilter, TNextFilter> getEntryByFilter(TFilter filter);

  /// Gets the entry with the specified filter type in this chain.
  CoapIEntry<TFilter, TNextFilter> getEntryByType(Type filterType);

  /// Gets the filter with the specified name in this chain.
  TFilter get(String name);

  /// Gets the next filter with the specified name in this chain.
  TNextFilter getNextFilterByName(String name);

  /// Gets the next filter with the specified filter in this chain.
  TNextFilter getNextFilterByFilter(TFilter filter);

  /// Gets the next filter with the specified filter type in this chain.
  TNextFilter getNextFilterByType(Type filterType);

  /// Gets all entries in this chain.
  Iterable<CoapEntry<dynamic, dynamic>> getAll();

  /// Checks if this chain contains a filter with the specified name.
  bool containsName(String name);

  /// Checks if this chain contains the specified filter.
  bool containsFilter(TFilter filter);

  /// Checks if this chain contains a filter with the specified filterType.
  bool containsType(Type filterType);

  /// Adds the specified filter with the specified name at the
  /// beginning of this chain.
  void addFirst(String name, TFilter filter);

  /// Adds the specified filter with the specified name at the
  /// end of this chain.
  void addLast(String name, TFilter filter);

  /// Adds the specified filter with the specified name just before the
  /// filter whose name is baseName in this chain.
  void addBefore(String baseName, String name, TFilter filter);

  /// Adds the specified filter with the specified name just after the
  /// filter whose name is baseName in this chain.
  void addAfter(String baseName, String name, TFilter filter);

  /// Replace the filter with the specified name with the specified new filter.
  TFilter replaceByName(String name, TFilter newFilter);

  /// Replace the specified filter with the specified new filter.
  void replaceByFilter(TFilter oldFilter, TFilter newFilter);

  /// Removes the filter with the specified name from this chain.
  TFilter removeByName(String name);

  /// Removes the specified filter.
  void removeByFilter(TFilter filter);

  /// Removes all filters added to this chain.
  void clear();
}

/// Represents an entry of filter in the chain.
class CoapEntry<TFilter, TNextFilter>
    implements CoapIEntry<TFilter, TNextFilter> {
  /// Instantiates.
  CoapEntry(this._chain, this.prevEntry, this.nextEntry, this.name,
      this._filter, TNextFilterFactory<dynamic, dynamic> nextFilterFactory) {
    if (filter == null) {
      throw ArgumentError.notNull('filter');
    }
    if (name == null) {
      throw ArgumentError.notNull('name');
    }
    nextFilter = nextFilterFactory(this);
  }

  final CoapChain<dynamic, dynamic, dynamic> _chain;

  /// The chain
  CoapChain<dynamic, dynamic, dynamic> get chain => _chain;

  @override
  String name;

  /// Previous entry
  CoapEntry<dynamic, dynamic> prevEntry;

  /// Next entry
  CoapEntry<dynamic, dynamic> nextEntry;

  TFilter _filter;

  @override
  TFilter get filter => _filter;

  @override
  set filter(TFilter value) {
    if (value == null) {
      throw ArgumentError.notNull('value');
    }
    _filter = value;
  }

  @override
  TNextFilter nextFilter;

  @override
  void addBefore(String name, TFilter filter) {
    _chain.addBefore(name, name, filter);
  }

  @override
  void addAfter(String name, TFilter filter) {
    _chain.addAfter(name, name, filter);
  }

  @override
  void replace(TFilter newFilter) {
    _chain.replaceByName(name, newFilter);
  }

  @override
  void remove() {
    _chain.removeByName(name);
  }

  @override
  String toString() {
    final sb = StringBuffer();

    // Add the current filter
    sb.write('(');
    sb.write(name);
    sb.write('\'');

    // Add the previous filter
    sb.write(', prev: ');

    if (prevEntry != null) {
      sb.write(prevEntry.name);
      sb.write(':');
      sb.write(prevEntry.filter.getType().name);
    } else {
      sb.write('null');
    }

    // Add the next filter
    sb.write(', next: ');

    if (nextEntry != null) {
      sb.write(nextEntry.name);
      sb.write(':');
      sb.write(nextEntry.filter.getType().name);
    } else {
      sb.write('null');
    }

    sb.write(')');
    return sb.toString();
  }
}

/// Implementation of IChain TFilter,TNextFilter
class CoapChain<TChain, TFilter, TNextFilter>
    implements CoapIChain<TFilter, TNextFilter> {
  /// Instantiates.
  CoapChain(
      TEntryFactoryFunc entryFactory,
      TFilterFactory<dynamic> headFilterFactory,
      TFilterFactory<dynamic> tailFilterFactory,
      TEqualsFunc equalsFunc) {
    _equalsFunc = equalsFunc;
    _entryFactory = entryFactory;
    _head = entryFactory(this, null, null, 'head', headFilterFactory());
    _tail = entryFactory(this, _head, null, 'tail', tailFilterFactory());
    _head.nextEntry = _tail;
  }

  /// Instantiates.
  CoapChain.entryFactory(
      TEntryFactoryFunc entryFactory,
      TFilterFactory<dynamic> headFilterFactory,
      TFilterFactory<dynamic> tailFilterFactory)
      : this(entryFactory, headFilterFactory, tailFilterFactory,
            <TFilter>(TFilter t1, TFilter t2) => t1 == t2);

  /// Instantiates.
  CoapChain.filterFactory(
      TNextFilterFactory<dynamic, dynamic> nextFilterFactory,
      TFilterFactory<dynamic> headFilterFactory,
      TFilterFactory<dynamic> tailFilterFactory)
      : this(
            <TChain, TFilter>(TChain chain,
                    CoapEntry<dynamic, dynamic> prev,
                    CoapEntry<dynamic, dynamic> next,
                    String name,
                    TFilter filter) =>
                CoapEntry<dynamic, dynamic>(
                    chain as CoapChain<dynamic, dynamic, dynamic>,
                    prev,
                    next,
                    name,
                    filter,
                    nextFilterFactory),
            headFilterFactory,
            tailFilterFactory,
            <TFilter>(TFilter t1, TFilter t2) => t1 == t2);

  final Map<String, CoapIEntry<dynamic, dynamic>> _name2entry =
      <String, CoapIEntry<dynamic, dynamic>>{};
  CoapEntry<dynamic, dynamic> _head;

  /// Head
  CoapEntry<dynamic, dynamic> get head => _head;
  CoapEntry<dynamic, dynamic> _tail;

  /// Tail
  CoapEntry<dynamic, dynamic> get tail => _tail;
  TEqualsFunc _equalsFunc;
  TEntryFactoryFunc _entryFactory;

  @override
  CoapIEntry<TFilter, TNextFilter> getEntryByName(String name) =>
      _name2entry[name];

  @override
  TFilter get(String name) {
    final e = getEntryByName(name);
    return e.filter;
  }

  @override
  CoapIEntry<TFilter, TNextFilter> getEntryByFilter(TFilter filter) {
    CoapEntry<TFilter, TNextFilter> e = _head.nextEntry;
    while (e != _tail) {
      if (_equalsFunc(e.filter, filter)) {
        return e;
      }
      e = e.nextEntry;
    }
    return null;
  }

  @override
  CoapIEntry<TFilter, TNextFilter> getEntryByType(Object filterType) {
    CoapEntry<TFilter, TNextFilter> e = _head.nextEntry;
    while (e != _tail) {
      if (filterType is TFilter) {
        return e;
      }
      e = e.nextEntry;
    }
    return null;
  }

  @override
  TNextFilter getNextFilterByName(String name) {
    final e = getEntryByName(name);
    return e.nextFilter;
  }

  @override
  TNextFilter getNextFilterByFilter(TFilter filter) {
    final e = getEntryByFilter(filter);
    return e.nextFilter;
  }

  @override
  TNextFilter getNextFilterByType(Object filterType) {
    final e = getEntryByType(filterType);
    return e.nextFilter;
  }

  @override
  Iterable<CoapEntry<dynamic, dynamic>> getAll() sync* {
    final e = _head.nextEntry;
    while (e != _tail) {
      yield e;
    }
  }

  @override
  bool containsName(String name) => getEntryByName(name) != null;

  @override
  bool containsFilter(TFilter filter) => getEntryByFilter(filter) != null;

  @override
  bool containsType(Object filterType) => getEntryByType(filterType) != null;

  @override
  void addFirst(String name, TFilter filter) {
    _checkAddable(name);
    _register(_head, name, filter);
  }

  @override
  void addLast(String name, TFilter filter) {
    _checkAddable(name);
    _register(_tail.prevEntry, name, filter);
  }

  @override
  void addAfter(String baseName, String name, TFilter filter) {
    final baseEntry = _checkOldName(baseName);
    _checkAddable(name);
    _register(baseEntry, name, filter);
  }

  @override
  void addBefore(String baseName, String name, TFilter filter) {
    final baseEntry = _checkOldName(baseName);
    _checkAddable(name);
    _register(baseEntry.prevEntry, name, filter);
  }

  @override
  TFilter replaceByName(String name, TFilter newFilter) {
    final entry = _checkOldName(name);
    final TFilter oldFilter = entry.filter;
    entry.filter = newFilter;
    return oldFilter;
  }

  @override
  void replaceByFilter(TFilter oldFilter, TFilter newFilter) {
    var e = _head.nextEntry;
    while (e != _tail) {
      if (_equalsFunc(e.filter, oldFilter)) {
        e.filter = newFilter;
        return;
      }
      e = e.nextEntry;
    }
    throw ArgumentError('Filter not found: $oldFilter');
  }

  @override
  TFilter removeByName(String name) {
    final entry = _checkOldName(name);
    _deregister(entry);
    return entry.filter;
  }

  @override
  void removeByFilter(TFilter filter) {
    var e = _head.nextEntry;
    while (e != _tail) {
      if (_equalsFunc(e.filter, filter)) {
        _deregister(e);
        return;
      }
      e = e.nextEntry;
    }
    throw ArgumentError('Filter not found: $filter');
  }

  @override
  void clear() {
    _name2entry.values.forEach(_deregister);
  }

  /// Fires after the entry is added to this chain.
  void onPostAdd(CoapEntry<dynamic, dynamic> entry) {}

  /// Fires before the entry is added to this chain.
  void onPreAdd(CoapEntry<dynamic, dynamic> entry) {}

  /// Fires before the entry is removed to this chain.
  void onPreRemove(CoapEntry<dynamic, dynamic> entry) {}

  /// Fires after the entry is removed to this chain.
  void onPostRemove(CoapEntry<dynamic, dynamic> entry) {}

  void _checkAddable(String name) {
    if (_name2entry.containsKey(name)) {
      throw ArgumentError('Other filter is using the same name $name');
    }
  }

  void _register(
      CoapEntry<dynamic, dynamic> prevEntry, String name, TFilter filter) {
    final newEntry =
        _entryFactory(this, prevEntry, prevEntry.nextEntry, name, filter);

    onPreAdd(newEntry);
    prevEntry.nextEntry.prevEntry = newEntry;
    prevEntry.nextEntry = newEntry;
    _name2entry[name] = newEntry;
    onPostAdd(newEntry);
  }

  CoapEntry<dynamic, dynamic> _checkOldName(String baseName) =>
      _name2entry[baseName];

  void _deregister(CoapEntry<dynamic, dynamic> entry) {
    onPreRemove(entry);
    _deregister0(entry);
    onPostRemove(entry);
  }

  /// Deregister an entry from this chain.
  void _deregister0(CoapEntry<dynamic, dynamic> entry) {
    final prevEntry = entry.prevEntry;
    final nextEntry = entry.nextEntry;
    prevEntry.nextEntry = nextEntry;
    nextEntry.prevEntry = prevEntry;
    _name2entry.remove(entry.name);
  }
}
