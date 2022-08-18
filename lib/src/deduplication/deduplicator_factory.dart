// ignore_for_file: avoid_classes_with_only_static_members

/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/05/2018
 * Copyright :  S.Hamblett
 */

import '../coap_config.dart';
import 'crop_rotation_deduplicator.dart';
import 'deduplicator.dart';
import 'noop_deduplicator.dart';
import 'sweep_deduplicator.dart';

/// Deduplicator factory
class DeduplicatorFactory {
  /// Mark and sweep
  static const String markAndSweepDeduplicator = 'MarkAndSweep';

  /// Crop rotation
  static const String cropRotationDeduplicator = 'CropRotation';

  /// Null(noop) deduplicator
  static const String noopDeduplicator = 'Noop';

  /// Create
  static Deduplicator createDeduplicator(final DefaultCoapConfig config) {
    final type = config.deduplicator;
    if (type == markAndSweepDeduplicator) {
      return SweepDeduplicator(config);
    } else if (type == cropRotationDeduplicator) {
      return CropRotationDeduplicator(config);
    }
    return NoopDeduplicator();
  }
}
