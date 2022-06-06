/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/05/2018
 * Copyright :  S.Hamblett
 */

import '../coap_config.dart';
import 'coap_crop_rotation_deduplicator.dart';
import 'coap_ideduplicator.dart';
import 'coap_noop_deduplicator.dart';
import 'coap_sweep_deduplicator.dart';

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
