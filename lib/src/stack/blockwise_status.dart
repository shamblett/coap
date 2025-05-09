/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

import 'package:typed_data/typed_data.dart';

import '../../coap.dart';

/// Represents the status of a blockwise transfer of a request or a response.
class BlockwiseStatus {
  /// Current num
  int currentNUM = 0;

  /// Vurrent SZX
  BlockSize currentSZX;

  /// Random access indicator
  bool randomAccess = false;

  /// Complete
  bool complete = false;

  /// Observe
  int? observe;

  /// Blocks
  List<Uint8Buffer> blocks = <Uint8Buffer>[];

  // The Content-Format must stay the same for the whole transfer.
  final CoapMediaType? _contentFormat;

  /// Random access indicator
  bool get isRandomAccess => randomAccess;

  /// Content format
  CoapMediaType? get contentFormat => _contentFormat;

  /// Block count
  int get blockCount => blocks.length;

  /// Instantiates a new blockwise status.
  BlockwiseStatus(this._contentFormat, this.currentSZX);

  /// Instantiates a new blockwise status.
  BlockwiseStatus.withSize(
    this._contentFormat,
    this.currentNUM,
    this.currentSZX,
  );

  /// Adds the specified block to the current list of blocks.
  void addBlock(final Uint8Buffer? block) {
    if (block != null) {
      blocks.add(block);
    }
  }

  @override
  String toString() =>
      '[CurrentNum=$currentNUM, CurrentSzx=$currentSZX, '
      'Complete=$complete, RandomAccess=$randomAccess]';
}
