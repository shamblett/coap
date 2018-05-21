/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 21/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

class CoapDeduplicatorFactory {
  static CoapILogger _log = new CoapLogManager("console").logger;

  static const String markAndSweepDeduplicator = "MarkAndSweep";
  static const String cropRotationDeduplicator = "CropRotation";
  static const String noopDeduplicator = "Noop";

  static CoapIDeduplicator createDeduplicator(CoapConfig config) {
    final String type = config.deduplicator;
    if (type == markAndSweepDeduplicator) {
      return new CoapSweepDeduplicator(config);
    } else if (type == cropRotationDeduplicator) {
      return new CoapCropRotation(config);
    } else if (type == noopDeduplicator) {
      _log.warn("Unknown deduplicator type: " + type);
    }
    return new CoapNoopDeduplicator();
  }
}
