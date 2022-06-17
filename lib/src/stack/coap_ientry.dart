/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/05/2018
 * Copyright :  S.Hamblett
 */

/// Represents a name-filter pair that an <see cref="IChain&lt;TFilter, TNextFilter&gt;"/> contains.
abstract class CoapIEntry<TFilter, TNextFilter> {
  /// Gets the name of the filter.
  String get name;

  /// Gets the filter.
  TFilter get filter;

  /// Sets the filter.
  set filter(final TFilter val);

  /// Gets the <typeparamref name="TNextFilter"/> of the filter.
  TNextFilter get nextFilter;

  /// Adds the specified filter with the specified name just before this entry.
  void addBefore(final String name, final TFilter filter);

  /// Adds the specified filter with the specified name just after this entry.
  void addAfter(final String name, final TFilter filter);

  /// Replace the filter of this entry with the specified new filter.
  void replace(final TFilter newFilter);

  /// Removes this entry from the chain it belongs to.
  void remove();
}
