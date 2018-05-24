/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Represents a name-filter pair that an <see cref="IChain&lt;TFilter, TNextFilter&gt;"/> contains.
abstract class CoapIEntry<TFilter, TNextFilter> {
  /// Gets the name of the filter.
  String name;

  /// Gets the filter.
  TFilter filter;

  /// Gets the <typeparamref name="TNextFilter"/> of the filter.
  TNextFilter nextFilter;

  /// Adds the specified filter with the specified name just before this entry.
  void addBefore(String name, TFilter filter);

  /// Adds the specified filter with the specified name just after this entry.
  void addAfter(String name, TFilter filter);

  /// Replace the filter of this entry with the specified new filter.
  void replace(TFilter newFilter);

  /// Removes this entry from the chain it belongs to.
  void remove();
}
