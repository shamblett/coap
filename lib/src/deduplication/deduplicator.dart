/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 03/05/2017
 * Copyright :  S.Hamblett
 */

import '../net/exchange.dart';

/// Provides methods to detect duplicates.
/// Note that CONs and NONs can be duplicates.
abstract class Deduplicator {
  /// Starts.
  void start();

  /// Stops.
  void stop();

  /// Clears the state of this deduplicator.
  void clear();

  /// Checks if the specified key is already associated with a previous
  /// exchange and otherwise associates the key with the exchange specified.
  CoapExchange? findPrevious(final int? key, final CoapExchange exchange);

  /// Finds the exchange associated with the supplied key
  CoapExchange? find(final int? key);
}
