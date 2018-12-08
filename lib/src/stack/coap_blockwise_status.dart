/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Represents the status of a blockwise transfer of a request or a response.
class CoapBlockwiseStatus {
  /// Instantiates a new blockwise status.
  CoapBlockwiseStatus(int contentFormat) {
    _contentFormat = contentFormat;
  }

  /// Instantiates a new blockwise status.
  CoapBlockwiseStatus.withSize(
      this._contentFormat, this.currentNUM, this.currentSZX);

  /// Not observing
  static const int noObserve = -1;

  /// Current num
  int currentNUM;

  /// Vurrent SZX
  int currentSZX;

  /// Random access indicator
  bool randomAccess;

  /// Random access indicator
  bool get isRandomAccess => randomAccess;

  /// The Content-Format must stay the same for the whole transfer.
  int _contentFormat;

  /// Content format
  int get contentFormat => _contentFormat;

  /// Complete
  bool complete;

  /// Observe
  int observe = noObserve;

  /// Blocks
  List<typed.Uint8Buffer> blocks = List<typed.Uint8Buffer>();

  /// Block count
  int get blockCount => blocks.length;

  /// Adds the specified block to the current list of blocks.
  void addBlock(typed.Uint8Buffer block) {
    if (block != null) {
      blocks.add(block);
    }
  }

  @override
  String toString() =>
      '[CurrentNum=$currentNUM, CurrentSzx=$currentSZX, Complete=$complete, RandomAccess=$randomAccess]';
}
