/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

typedef bool TEqualsFunc<TFilter>(TFilter a, TFilter b);
typedef CoapEntry TEntryFactoryFunc<TChain, TFilter>(TChain a, CoapEntry b,
    CoapEntry c, String d, TFilter e);
typedef TNextFilter TNextFilterFactory<TNextFilter, TFilter>(TFilter);
typedef TFilter TFilterFactory<TFilter>();

/// Represents a chain of filters.
abstract class CoapIChain<TFilter, TNextFilter> {
  /// Gets the <see cref="IEntry&lt;TFilter, TNextFilter&gt;"/> with the specified <paramref name="name"/> in this chain.
  CoapIEntry<TFilter, TNextFilter> getEntryByName(String name);

  /// Gets the <see cref="IEntry&lt;TFilter, TNextFilter&gt;"/> with the specified <paramref name="filter"/> in this chain.
  CoapIEntry<TFilter, TNextFilter> getEntryByFilter(TFilter filter);

  /// Gets the <see cref="IEntry&lt;TFilter, TNextFilter&gt;"/> with the specified <paramref name="filterType"/> in this chain.
  CoapIEntry<TFilter, TNextFilter> getEntryByType(Type filterType);

  /// Gets the <typeparamref name="TFilter"/> with the specified <paramref name="name"/> in this chain.
  TFilter get(String name);

  /// Gets the <typeparamref name="TNextFilter"/> of the <typeparamref name="TFilter"/>
  /// with the specified <paramref name="name"/> in this chain.
  TNextFilter getNextFilterByName(String name);

  /// Gets the <typeparamref name="TNextFilter"/> of the <typeparamref name="TFilter"/>
  /// with the specified <paramref name="filter"/> in this chain.
  TNextFilter getNextFilterByFilter(TFilter filter);

  /// Gets the <typeparamref name="TNextFilter"/> of the <typeparamref name="TFilter"/>
  /// with the specified <paramref name="filterType"/> in this chain.
  TNextFilter getNextFilterByType(Type filterType);

  /// Gets all <see cref="IEntry&lt;TFilter, TNextFilter&gt;"/>s in this chain.
  Iterable<CoapEntry> getAll();

  /// Checks if this chain contains a filter with the specified <paramref name="name"/>.
  bool containsName(String name);

  /// Checks if this chain contains the specified <paramref name="filter"/>.
  bool containsFilter(TFilter filter);

  /// Checks if this chain contains a filter with the specified <paramref name="filterType"/>.
  bool containsType(Type filterType);

  /// Adds the specified filter with the specified name at the beginning of this chain.
  void addFirst(String name, TFilter filter);

  /// Adds the specified filter with the specified name at the end of this chain.
  void addLast(String name, TFilter filter);

  /// Adds the specified filter with the specified name just before the filter whose name is
  /// <paramref name="baseName"/> in this chain.
  void addBefore(String baseName, String name, TFilter filter);

  /// Adds the specified filter with the specified name just after the filter whose name is
  /// <paramref name="baseName"/> in this chain.
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
  CoapEntry(CoapChain chain, CoapEntry prevEntry, CoapEntry nextEntry,
      String name, TFilter filter, TNextFilterFactory nextFilterFactory) {
    if (filter == null) throw new ArgumentError.notNull("filter");
    if (name == null) throw new ArgumentError.notNull("name");

    _chain = chain;
    _prevEntry = prevEntry;
    _nextEntry = nextEntry;
    _name = name;
    _filter = filter;
    _nextFilter = nextFilterFactory(this);
  }

  CoapChain _chain;

  CoapChain get chain => _chain;
  String _name;

  String get name => _name;

  set name(String name) => _name = name;
  CoapEntry _prevEntry;

  CoapEntry get prevEntry => _prevEntry;

  set prevEntry(CoapEntry entry) => _prevEntry = entry;

  CoapEntry _nextEntry;

  CoapEntry get nextEntry => _nextEntry;

  set nextEntry(CoapEntry entry) => _nextEntry = entry;
  TFilter _filter;

  TFilter get filter => _filter;

  set filter(TFilter value) {
    if (value == null) {
      throw new ArgumentError.notNull("value");
    }
    _filter = value;
  }

  TNextFilter _nextFilter;

  TNextFilter get nextFilter => _nextFilter;

  set nextFilter(TNextFilter filter) => _nextFilter = filter;

  void addBefore(String name, TFilter filter) {
    _chain.addBefore(_name, name, filter);
  }

  void addAfter(String name, TFilter filter) {
    _chain.addAfter(_name, name, filter);
  }

  void replace(TFilter newFilter) {
    _chain.replaceByName(_name, newFilter);
  }

  void remove() {
    _chain.removeByName(_name);
  }

  @override
  String toString() {
    final StringBuffer sb = new StringBuffer();

    // Add the current filter
    sb.write("('");
    sb.write(name);
    sb.write('\'');

    // Add the previous filter
    sb.write(", prev: '");

    if (_prevEntry != null) {
      sb.write(_prevEntry.name);
      sb.write(':');
      sb.write(_prevEntry.filter
          .getType()
          .name);
    } else {
      sb.write("null");
    }

    // Add the next filter
    sb.write("', next: '");

    if (_nextEntry != null) {
      sb.write(_nextEntry.name);
      sb.write(':');
      sb.write(_nextEntry.filter
          .getType()
          .name);
    } else {
      sb.write("null");
    }

    sb.write("')");
    return sb.toString();
  }
}

/// Implementation of <see cref="IChain&lt;TFilter, TNextFilter&gt;"/>
class CoapChain<TChain, TFilter, TNextFilter>
    implements CoapIChain<TFilter, TNextFilter> {
  /// Instantiates.
  CoapChain(TEntryFactoryFunc entryFactory, TFilterFactory headFilterFactory,
      TFilterFactory tailFilterFactory, TEqualsFunc equalsFunc) {
    _equalsFunc = equalsFunc;
    _entryFactory = entryFactory;
    _head = entryFactory(this, null, null, "head", headFilterFactory());
    _tail = entryFactory(this, _head, null, "tail", tailFilterFactory());
    _head._nextEntry = _tail;
  }

  /// Instantiates.
  CoapChain.objectEquals(TNextFilterFactory nextFilterFactory,
      TFilterFactory headFilterFactory, TFilterFactory tailFilterFactory)
      : this(
          (chain, prev, next, name, filter) =>
      new CoapEntry(
          chain, prev, next, name, filter, nextFilterFactory),
      headFilterFactory,
      tailFilterFactory,
          (t1, t2) => t1 == t2);

  /// Instantiates.
  CoapChain.noEquals(TNextFilterFactory nextFilterFactory,
      TFilterFactory headFilterFactory, TFilterFactory tailFilterFactory)
      : this(
          (chain, prev, next, name, filter) =>
      new CoapEntry(
          chain, prev, next, name, filter, nextFilterFactory),
      headFilterFactory,
      tailFilterFactory,
      null);

  Map<String, CoapIEntry<TFilter, TNextFilter>> _name2entry =
  new Map<String, CoapIEntry<TFilter, TNextFilter>>();
  CoapEntry _head;

  CoapEntry get head => _head;
  CoapEntry _tail;

  CoapEntry get tail => _tail;
  TEqualsFunc _equalsFunc;
  TEntryFactoryFunc _entryFactory;

  CoapIEntry<TFilter, TNextFilter> getEntryByName(String name) {
    return _name2entry[name];
  }

  TFilter get(String name) {
    final CoapIEntry<TFilter, TNextFilter> e = getEntryByName(name);
    return e.filter;
  }

  CoapIEntry<TFilter, TNextFilter> getEntryByFilter(TFilter filter) {
    CoapEntry e = _head._nextEntry;
    while (e != _tail) {
      if (_equalsFunc(e.filter, filter)) {
        return e as CoapIEntry<TFilter, TNextFilter>;
      }
      e = e.nextEntry;
    }
    return null;
  }

  CoapIEntry<TFilter, TNextFilter> getEntryByType(Object filterType) {
    CoapIEntry<TFilter, TNextFilter> e =
    _head.nextEntry as CoapIEntry<TFilter, TNextFilter>;
    while (e != _tail as CoapIEntry<TFilter, TNextFilter>) {
      if (filterType is TFilter) {
        return e;
      }
      e = ((e as CoapEntry).nextEntry) as CoapIEntry<TFilter, TNextFilter>;
    }
    return null;
  }

  TNextFilter getNextFilterByName(String name) {
    final CoapIEntry<TFilter, TNextFilter> e = getEntryByName(name);
    return e.nextFilter;
  }

  TNextFilter getNextFilterByFilter(TFilter filter) {
    final CoapIEntry<TFilter, TNextFilter> e = getEntryByFilter(filter);
    return e.nextFilter;
  }

  TNextFilter getNextFilterByType(Object filterType) {
    final CoapIEntry<TFilter, TNextFilter> e = getEntryByType(filterType);
    return e.nextFilter;
  }

  Iterable<CoapEntry> getAll() sync* {
    final CoapEntry e = _head.nextEntry;
    while (e != _tail) {
      yield e;
    }
  }

  bool containsName(String name) {
    return getEntryByName(name) != null;
  }

  bool containsFilter(TFilter filter) {
    return getEntryByFilter(filter) != null;
  }

  bool containsType(Object filterType) {
    return getEntryByType(filterType) != null;
  }

  void addFirst(String name, TFilter filter) {
    _checkAddable(name);
    _register(_head, name, filter);
  }

  void addLast(String name, TFilter filter) {
    _checkAddable(name);
    _register(_tail.prevEntry, name, filter);
  }

  void addAfter(String baseName, String name, TFilter filter) {
    final CoapEntry baseEntry = _checkOldName(baseName);
    _checkAddable(name);
    _register(baseEntry, name, filter);
  }

  void addBefore(String baseName, String name, TFilter filter) {
    final CoapEntry baseEntry = _checkOldName(baseName);
    _checkAddable(name);
    _register(baseEntry.prevEntry, name, filter);
  }

  TFilter replaceByName(String name, TFilter newFilter) {
    final CoapEntry entry = _checkOldName(name);
    final TFilter oldFilter = entry.filter;
    entry.filter = newFilter;
    return oldFilter;
  }

  void replaceByFilter(TFilter oldFilter, TFilter newFilter) {
    CoapEntry e = _head.nextEntry;
    while (e != _tail) {
      if (_equalsFunc(e.filter, oldFilter)) {
        e.filter = newFilter;
        return;
      }
      e = e.nextEntry;
    }
    throw new ArgumentError("Filter not found: ${oldFilter}");
  }

  TFilter removeByName(String name) {
    final CoapEntry entry = _checkOldName(name);
    _deregister(entry);
    return entry.filter;
  }

  void removeByFilter(TFilter filter) {
    CoapEntry e = _head.nextEntry;
    while (e != _tail) {
      if (_equalsFunc(e.filter, filter)) {
        _deregister(e);
        return;
      }
      e = e.nextEntry;
    }
    throw new ArgumentError("Filter not found: ${filter}");
  }

  void clear() {
    for (CoapIEntry<TFilter, TNextFilter> entry in _name2entry.values) {
      _deregister(entry as CoapEntry);
    }
  }

  /// Fires after the entry is added to this chain.
  void onPostAdd(CoapEntry entry) {}

  /// Fires before the entry is added to this chain.
  void onPreAdd(CoapEntry entry) {}

  /// Fires before the entry is removed to this chain.
  void onPreRemove(CoapEntry entry) {}

  /// Fires after the entry is removed to this chain.
  void onPostRemove(CoapEntry entry) {}

  void _checkAddable(String name) {
    if (_name2entry.containsKey(name)) {
      throw new ArgumentError("Other filter is using the same name $name");
    }
  }

  void _register(CoapEntry prevEntry, String name, TFilter filter) {
    final CoapEntry newEntry =
    _entryFactory(this, prevEntry, prevEntry.nextEntry, name, filter);

    onPreAdd(newEntry);
    prevEntry.nextEntry.prevEntry = newEntry;
    prevEntry.nextEntry = newEntry;
    _name2entry[name] = newEntry as CoapIEntry<TFilter, TNextFilter>;
    onPostAdd(newEntry);
  }

  CoapEntry _checkOldName(String baseName) {
    return _name2entry[baseName] as CoapEntry;
  }

  void _deregister(CoapEntry entry) {
    onPreRemove(entry);
    _deregister0(entry);
    onPostRemove(entry);
  }

  /// Deregister an entry from this chain.
  void _deregister0(CoapEntry entry) {
    final CoapEntry prevEntry = entry.prevEntry;
    final CoapEntry nextEntry = entry.nextEntry;
    prevEntry.nextEntry = nextEntry;
    nextEntry.prevEntry = prevEntry;
    _name2entry.remove(entry.name);
  }
}
