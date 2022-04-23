/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Deduplicator factory
class CoapDeduplicatorFactory {
  /// Mark and sweep
  static const String markAndSweepDeduplicator = 'MarkAndSweep';

  /// Crop rotation
  static const String cropRotationDeduplicator = 'CropRotation';

  /// Null(noop) deduplicator
  static const String noopDeduplicator = 'Noop';

  /// Create
  static CoapIDeduplicator createDeduplicator(DefaultCoapConfig config) {
    final type = config.deduplicator;
    if (type == markAndSweepDeduplicator) {
      return CoapSweepDeduplicator(config);
    } else if (type == cropRotationDeduplicator) {
      return CoapCropRotationDeduplicator(config);
    }
    return CoapNoopDeduplicator();
  }
}
