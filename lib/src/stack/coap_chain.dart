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
  CoapIEntry<TFilter, TNextFilter> GetEntryByType(Type filterType);

  /// Gets the <typeparamref name="TFilter"/> with the specified <paramref name="name"/> in this chain.
  TFilter get(String name);

  /// Gets the <typeparamref name="TNextFilter"/> of the <typeparamref name="TFilter"/>
  /// with the specified <paramref name="name"/> in this chain.
  TNextFilter getNextFilter(String name);

  /// Gets the <typeparamref name="TNextFilter"/> of the <typeparamref name="TFilter"/>
  /// with the specified <paramref name="filter"/> in this chain.
  TNextFilter getNextFilterByFilter(TFilter filter);

  /// Gets the <typeparamref name="TNextFilter"/> of the <typeparamref name="TFilter"/>
  /// with the specified <paramref name="filterType"/> in this chain.
  TNextFilter getNextFilterByType(Type filterType);

  /// Gets all <see cref="IEntry&lt;TFilter, TNextFilter&gt;"/>s in this chain.
  Iterable<CoapIEntry<TFilter, TNextFilter>> getAll();

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
  CoapEntry _nextEntry;

  CoapEntry get nextEntry => _nextEntry;
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
    _chain.replace(_name, newFilter);
  }

  void remove() {
    _chain.remove(_name);
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();

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
  CoapChain.NoEquals(TNextFilterFactory nextFilterFactory,
      TFilterFactory headFilterFactory, TFilterFactory tailFilterFactory)
      : this(
          (chain, prev, next, name, filter) =>
      new CoapEntry(
          chain, prev, next, name, filter, nextFilterFactory),
      headFilterFactory,
      tailFilterFactory,
          (t1, t2) => t1 == t2);

  /// Instantiates.
  //CoapChain(TNextFilterFactory nextFilterFactory, TFilterFactory headFilterFactory, TFilterFactory tailFilterFactory)
  //    : this((chain, prev, next, name, filter) => new Entry(chain, prev, next, name, filter, nextFilterFactory),
  //    headFilterFactory, tailFilterFactory)
  // { }

  Map<String, CoapEntry> _name2entry = new Map<String, CoapEntry>();
  CoapEntry _head;
  CoapEntry _tail;
  TEqualsFunc _equalsFunc;
  TEntryFactoryFunc _entryFactory;
}
