/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

import 'package:typed_data/typed_data.dart';

import '../../coap.dart';

/// Represents the status of a blockwise transfer of a request or a response.
class CoapBlockwiseStatus {
  /// Instantiates a new blockwise status.
  CoapBlockwiseStatus(this._contentFormat);

  /// Instantiates a new blockwise status.
  CoapBlockwiseStatus.withSize(
    this._contentFormat,
    this.currentNUM,
    this.currentSZX,
  );

  /// Not observing
  static const int noObserve = -1;

  /// Current num
  int currentNUM = 0;

  /// Vurrent SZX
  int currentSZX = 0;

  /// Random access indicator
  bool randomAccess = false;

  /// Random access indicator
  bool get isRandomAccess => randomAccess;

  /// The Content-Format must stay the same for the whole transfer.
  final CoapMediaType? _contentFormat;

  /// Content format
  CoapMediaType? get contentFormat => _contentFormat;

  /// Complete
  bool complete = false;

  /// Observe
  int observe = noObserve;

  /// Blocks
  List<Uint8Buffer> blocks = <Uint8Buffer>[];

  /// Block count
  int get blockCount => blocks.length;

  /// Adds the specified block to the current list of blocks.
  void addBlock(final Uint8Buffer? block) {
    if (block != null) {
      blocks.add(block);
    }
  }

  @override
  String toString() => '[CurrentNum=$currentNUM, CurrentSzx=$currentSZX, '
      'Complete=$complete, RandomAccess=$randomAccess]';
}
