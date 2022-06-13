/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/05/2018
 * Copyright :  S.Hamblett
 */

import 'coap_ientry.dart';

typedef TEqualsFunc = bool Function<TFilter>(TFilter a, TFilter b);
typedef TEntryFactoryFunc = CoapEntry<dynamic, dynamic>
    Function<TChain, TFilter>(
  TChain a,
  CoapEntry<dynamic, dynamic>? b,
  CoapEntry<dynamic, dynamic>? c,
  String d,
  TFilter e,
);
typedef TNextFilterFactory<TNextFilter, TFilter> = TNextFilter Function(
  TFilter v,
);
typedef TFilterFactory<TFilter> = TFilter Function();

/// Represents a chain of filters.
abstract class CoapIChain<TFilter, TNextFilter> {
  /// Gets the entry with the specified name in this chain.
  CoapIEntry<TFilter, TNextFilter>? getEntryByName(final String name);

  /// Gets the entry with the specified filter in this chain.
  CoapIEntry<TFilter, TNextFilter> getEntryByFilter(final TFilter filter);

  /// Gets the entry with the specified filter type in this chain.
  CoapIEntry<TFilter, TNextFilter> getEntryByType(final Type filterType);

  /// Gets the filter with the specified name in this chain.
  TFilter get(final String name);

  /// Gets the next filter with the specified name in this chain.
  TNextFilter getNextFilterByName(final String name);

  /// Gets the next filter with the specified filter in this chain.
  TNextFilter getNextFilterByFilter(final TFilter filter);

  /// Gets the next filter with the specified filter type in this chain.
  TNextFilter getNextFilterByType(final Type filterType);

  /// Gets all entries in this chain.
  Iterable<CoapEntry<dynamic, dynamic>> getAll();

  /// Checks if this chain contains a filter with the specified name.
  bool containsName(final String name);

  /// Checks if this chain contains the specified filter.
  bool containsFilter(final TFilter filter);

  /// Checks if this chain contains a filter with the specified filterType.
  bool containsType(final Type filterType);

  /// Adds the specified filter with the specified name at the
  /// beginning of this chain.
  void addFirst(final String name, final TFilter filter);

  /// Adds the specified filter with the specified name at the
  /// end of this chain.
  void addLast(final String name, final TFilter filter);

  /// Adds the specified filter with the specified name just before the
  /// filter whose name is baseName in this chain.
  void addBefore(
    final String baseName,
    final String name,
    final TFilter filter,
  );

  /// Adds the specified filter with the specified name just after the
  /// filter whose name is baseName in this chain.
  void addAfter(final String baseName, final String name, final TFilter filter);

  /// Replace the filter with the specified name with the specified new filter.
  TFilter replaceByName(final String name, final TFilter newFilter);

  /// Replace the specified filter with the specified new filter.
  void replaceByFilter(final TFilter oldFilter, final TFilter newFilter);

  /// Removes the filter with the specified name from this chain.
  TFilter removeByName(final String name);

  /// Removes the specified filter.
  void removeByFilter(final TFilter filter);

  /// Removes all filters added to this chain.
  void clear();
}

/// Represents an entry of filter in the chain.
class CoapEntry<TFilter, TNextFilter>
    implements CoapIEntry<TFilter, TNextFilter> {
  /// Instantiates.
  CoapEntry(
    this._chain,
    this.prevEntry,
    this.nextEntry,
    this._name,
    this._filter,
    final TNextFilterFactory<dynamic, dynamic> nextFilterFactory,
  ) {
    nextFilter = nextFilterFactory(this) as TNextFilter;
  }

  final CoapChain<dynamic, dynamic, dynamic> _chain;

  /// The chain
  CoapChain<dynamic, dynamic, dynamic> get chain => _chain;

  /// Previous entry
  CoapEntry<dynamic, dynamic>? prevEntry;

  /// Next entry
  CoapEntry<dynamic, dynamic>? nextEntry;

  final String _name;

  @override
  String get name => _name;

  TFilter _filter;

  @override
  TFilter get filter => _filter;

  @override
  set filter(final TFilter value) {
    _filter = value;
  }

  @override
  late TNextFilter nextFilter;

  @override
  void addBefore(final String name, final TFilter filter) {
    _chain.addBefore(name, name, filter);
  }

  @override
  void addAfter(final String name, final TFilter filter) {
    _chain.addAfter(name, name, filter);
  }

  @override
  void replace(final TFilter newFilter) {
    _chain.replaceByName(name, newFilter);
  }

  @override
  void remove() {
    _chain.removeByName(name);
  }

  @override
  String toString() {
    final sb = StringBuffer('($name, prev: ');

    if (prevEntry != null) {
      sb
        ..write('${prevEntry!.name}:')
        ..write(prevEntry!.filter.getType().name);
    } else {
      sb.write('null');
    }

    sb.write(', next: ');
    if (nextEntry != null) {
      sb
        ..write('${nextEntry!.name}:')
        ..write(nextEntry!.filter.getType().name);
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
    final TEntryFactoryFunc entryFactory,
    final TFilterFactory<dynamic> headFilterFactory,
    final TFilterFactory<dynamic> tailFilterFactory,
    final TEqualsFunc equalsFunc,
  ) {
    _equalsFunc = equalsFunc;
    _entryFactory = entryFactory;
    _head = entryFactory(this, null, null, 'head', headFilterFactory());
    _tail = entryFactory(this, _head, null, 'tail', tailFilterFactory());
    _head!.nextEntry = _tail;
  }

  /// Instantiates.
  CoapChain.entryFactory(
    final TEntryFactoryFunc entryFactory,
    final TFilterFactory<dynamic> headFilterFactory,
    final TFilterFactory<dynamic> tailFilterFactory,
  ) : this(
          entryFactory,
          headFilterFactory,
          tailFilterFactory,
          <TFilter>(final t1, final t2) => t1 == t2,
        );

  /// Instantiates.
  CoapChain.filterFactory(
    final TNextFilterFactory<dynamic, dynamic> nextFilterFactory,
    final TFilterFactory<dynamic> headFilterFactory,
    final TFilterFactory<dynamic> tailFilterFactory,
  ) : this(
          <TChain, TFilter>(
            final chain,
            final prev,
            final next,
            final name,
            final filter,
          ) =>
              CoapEntry<dynamic, dynamic>(
            chain as CoapChain<dynamic, dynamic, dynamic>,
            prev,
            next,
            name,
            filter,
            nextFilterFactory,
          ),
          headFilterFactory,
          tailFilterFactory,
          <TFilter>(final t1, final t2) => t1 == t2,
        );

  final Map<String, CoapIEntry<dynamic, dynamic>> _name2entry =
      <String, CoapIEntry<dynamic, dynamic>>{};
  CoapEntry<dynamic, dynamic>? _head;

  /// Head
  CoapEntry<dynamic, dynamic>? get head => _head;
  CoapEntry<dynamic, dynamic>? _tail;

  /// Tail
  CoapEntry<dynamic, dynamic>? get tail => _tail;
  late TEqualsFunc _equalsFunc;
  late TEntryFactoryFunc? _entryFactory;

  @override
  CoapIEntry<TFilter, TNextFilter>? getEntryByName(final String name) =>
      _name2entry[name] as CoapIEntry<TFilter, TNextFilter>?;

  @override
  TFilter get(final String name) {
    final e = getEntryByName(name)!;
    return e.filter;
  }

  @override
  CoapIEntry<TFilter, TNextFilter> getEntryByFilter(final TFilter filter) {
    var e = _head!.nextEntry as CoapEntry<TFilter, TNextFilter>?;
    while (e != _tail) {
      if (_equalsFunc(e!.filter, filter)) {
        return e;
      }
      e = e.nextEntry as CoapEntry<TFilter, TNextFilter>?;
    }
    return e!;
  }

  @override
  CoapIEntry<TFilter, TNextFilter> getEntryByType(final Object filterType) {
    var e = _head!.nextEntry! as CoapEntry<TFilter, TNextFilter>;
    while (e != _tail) {
      if (filterType is TFilter) {
        return e;
      }
      e = e.nextEntry! as CoapEntry<TFilter, TNextFilter>;
    }
    return e;
  }

  @override
  TNextFilter getNextFilterByName(final String name) {
    final e = getEntryByName(name)!;
    return e.nextFilter!;
  }

  @override
  TNextFilter getNextFilterByFilter(final TFilter filter) {
    final e = getEntryByFilter(filter);
    return e.nextFilter!;
  }

  @override
  TNextFilter getNextFilterByType(final Object filterType) {
    final e = getEntryByType(filterType);
    return e.nextFilter!;
  }

  @override
  Iterable<CoapEntry<dynamic, dynamic>> getAll() sync* {
    final e = _head!.nextEntry!;
    while (e != _tail) {
      yield e;
    }
  }

  @override
  bool containsName(final String name) => getEntryByName(name) != null;

  @override
  bool containsFilter(final TFilter filter) =>
      getEntryByFilter(filter).filter != null;

  @override
  bool containsType(final Object filterType) =>
      getEntryByType(filterType).filter != null;

  @override
  void addFirst(final String name, final TFilter filter) {
    _checkAddable(name);
    _register(_head!, name, filter);
  }

  @override
  void addLast(final String name, final TFilter filter) {
    _checkAddable(name);
    _register(_tail!.prevEntry!, name, filter);
  }

  @override
  void addAfter(
    final String baseName,
    final String name,
    final TFilter filter,
  ) {
    final baseEntry = _checkOldName(baseName);
    _checkAddable(name);
    _register(baseEntry, name, filter);
  }

  @override
  void addBefore(
    final String baseName,
    final String name,
    final TFilter filter,
  ) {
    final baseEntry = _checkOldName(baseName);
    _checkAddable(name);
    _register(baseEntry.prevEntry!, name, filter);
  }

  @override
  TFilter replaceByName(final String? name, final TFilter newFilter) {
    final entry = _checkOldName(name!);
    final oldFilter = entry.filter as TFilter;
    entry.filter = newFilter;
    return oldFilter;
  }

  @override
  void replaceByFilter(final TFilter oldFilter, final TFilter newFilter) {
    var e = _head!.nextEntry!;
    while (e != _tail) {
      if (_equalsFunc(e.filter, oldFilter)) {
        e.filter = newFilter;
        return;
      }
      e = e.nextEntry!;
    }
    throw ArgumentError('Filter not found: $oldFilter');
  }

  @override
  TFilter removeByName(final String? name) {
    final entry = _checkOldName(name!);
    _deregister(entry);
    return entry.filter as TFilter;
  }

  @override
  void removeByFilter(final TFilter filter) {
    var e = _head!.nextEntry!;
    while (e != _tail) {
      if (_equalsFunc(e.filter, filter)) {
        _deregister(e);
        return;
      }
      e = e.nextEntry!;
    }
    throw ArgumentError('Filter not found: $filter');
  }

  @override
  void clear() {
    _name2entry.values
        .forEach(_deregister as void Function(CoapIEntry<dynamic, dynamic>));
  }

  /// Fires after the entry is added to this chain.
  void onPostAdd(final CoapEntry<dynamic, dynamic> entry) {}

  /// Fires before the entry is added to this chain.
  void onPreAdd(final CoapEntry<dynamic, dynamic> entry) {}

  /// Fires before the entry is removed to this chain.
  void onPreRemove(final CoapEntry<dynamic, dynamic> entry) {}

  /// Fires after the entry is removed to this chain.
  void onPostRemove(final CoapEntry<dynamic, dynamic> entry) {}

  void _checkAddable(final String name) {
    if (_name2entry.containsKey(name)) {
      throw ArgumentError('Other filter is using the same name $name');
    }
  }

  void _register(
    final CoapEntry<dynamic, dynamic> prevEntry,
    final String name,
    final TFilter filter,
  ) {
    final newEntry =
        _entryFactory!(this, prevEntry, prevEntry.nextEntry, name, filter);

    onPreAdd(newEntry);
    prevEntry.nextEntry!.prevEntry = newEntry;
    prevEntry.nextEntry = newEntry;
    _name2entry[name] = newEntry;
    onPostAdd(newEntry);
  }

  CoapEntry<dynamic, dynamic> _checkOldName(final String baseName) =>
      _name2entry[baseName]! as CoapEntry<dynamic, dynamic>;

  void _deregister(final CoapEntry<dynamic, dynamic> entry) {
    onPreRemove(entry);
    _deregister0(entry);
    onPostRemove(entry);
  }

  /// Deregister an entry from this chain.
  void _deregister0(final CoapEntry<dynamic, dynamic> entry) {
    final prevEntry = entry.prevEntry!;
    final nextEntry = entry.nextEntry!;
    prevEntry.nextEntry = nextEntry;
    nextEntry.prevEntry = prevEntry;
    _name2entry.remove(entry.name);
  }
}
