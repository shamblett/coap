/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 03/05/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Provides methods to detect duplicates.
/// Note that CONs and NONs can be duplicates.
abstract class CoapIDeduplicator {
  /// Starts.
  void start();

  /// Stops.
  void stop();

  /// Clears the state of this deduplicator.
  void clear();

/// Checks if the specified key is already associated with a previous
/// exchange and otherwise associates the key with the exchange specified.
/// Returns>the previous exchange associated with the specified key,
/// or null if there was no mapping for the key.
//Exchange FindPrevious(Exchange.KeyID key, Exchange exchange);
//Exchange Find(Exchange.KeyID key);
}
