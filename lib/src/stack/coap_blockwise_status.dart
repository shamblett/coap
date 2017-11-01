/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Represents the status of a blockwise transfer of a request or a response.
class CoapBlockwiseStatus {
  static const int noObserve = -1;

  /// Instantiates a new blockwise status.
  CoapBlockwiseStatus(int contentFormat) {
    _contentFormat = contentFormat;
  }

  /// Instantiates a new blockwise status.
  CoapBlockwiseStatus.withSize(int contentFormat, int num, int szx) {
    _contentFormat = contentFormat;
    currentNUM = num;
    currentSZX = szx;
  }

  int currentNUM;
  int currentSZX;
  bool randomAccess;

  bool get isRandomAccess => randomAccess;

  /// The Content-Format must stay the same for the whole transfer.
  int _contentFormat;

  int get contentFormat => _contentFormat;
  bool complete;
  int observe = noObserve;
  List<int> blocks = new List<int>();

  int get blockCount => blocks.length;

  /// Adds the specified block to the current list of blocks.
  void addBlock(int block) {
    if (block != null) blocks.Add(block);
  }

  String toString() {
    return "[CurrentNum=$currentNUM, CurrentSzx=$currentSZX, Complete=$complete, RandomAccess=$randomAccess]";
  }
}
