/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// This class describes the CoAP Media Type Registry as defined in
/// RFC 7252, Section 12.3.
class CoapMediaType {
  /// Media registry
  static final Map<int, List<String>> _registry = <int, List<String>>{
    textPlain: <String>['text/plain', 'txt'],
    imageGif: <String>['image/gif', 'gif'],
    imageJpeg: <String>['image/jpeg', 'jpg'],
    imagePng: <String>['image/png', 'png'],
    applicationLinkFormat: <String>['application/link-format', 'wlnk'],
    applicationXml: <String>['application/xml', 'xml'],
    applicationOctetStream: <String>['application/octet-stream', 'bin'],
    applicationExi: <String>['application/exi', 'exi'],
    applicationJson: <String>['application/json', 'json']
  };

  /// undefined
  static const int undefined = -1;

  /// text/plain; charset=utf-8
  static const int textPlain = 0;

  /// image/gif
  static const int imageGif = 21;

  /// image/jpeg
  static const int imageJpeg = 22;

  /// image/png
  static const int imagePng = 23;

  /// application/link-format
  static const int applicationLinkFormat = 40;

  /// application/xml
  static const int applicationXml = 41;

  /// application/octet-stream
  static const int applicationOctetStream = 42;

  /// application/exi
  static const int applicationExi = 47;

  /// application/json
  static const int applicationJson = 50;

  /// any
  static const int any = 0xFF;

  /// Checks whether the given media type is a type of image.
  /// True iff the media type is a type of image.
  static bool isImage(int mediaType) =>
      mediaType >= imageGif && mediaType <= imagePng;

  /// Is the media type printable
  static bool isPrintable(int? mediaType) {
    switch (mediaType) {
      case textPlain:
      case applicationLinkFormat:
      case applicationXml:
      case applicationJson:
      case undefined:
        return true;
      default:
        return false;
    }
  }

  /// Returns a string representation of the media type.
  static String name(int mediaType) {
    if (_registry.containsKey(mediaType)) {
      return _registry[mediaType]![0];
    } else {
      return 'unknown/$mediaType';
    }
  }

  /// Gets the file extension of the given media type.
  static String fileExtension(int mediaType) {
    if (_registry.containsKey(mediaType)) {
      return _registry[mediaType]![1];
    } else {
      return 'unknown/$mediaType';
    }
  }

  /// Negotiation content
  static int negotiationContent(
      int defaultContentType, List<int> supported, List<CoapOption>? accepted) {
    if (accepted == null) {
      return defaultContentType;
    }
    var hasAccept = false;
    for (final opt in accepted) {
      for (final ct in supported) {
        if (ct == opt.intValue) {
          return ct;
        }
      }
      hasAccept = true;
    }
    return hasAccept ? CoapMediaType.undefined : defaultContentType;
  }

  /// Parse
  static int? parse(String? type) {
    if (type == null) {
      return CoapMediaType.undefined;
    }
    int? keyRet;
    _registry.forEach((int key, List<String> value) {
      if (value[0].toLowerCase() == type.toLowerCase()) {
        keyRet = key;
      }
    });
    if (keyRet != null) {
      return keyRet;
    } else {
      return CoapMediaType.undefined;
    }
  }

  /// Wildcard parse
  static List<int>? parseWildcard(String? regex) {
    if (regex == null) {
      return null;
    }
    final res = <int>[];
    var regex1 = regex.trim().substring(0, regex.indexOf('*')).trim();
    regex1 += '.*';
    final r = RegExp(regex1);
    _registry.forEach((int key, List<String> value) {
      final mime = value[0];
      if (r.hasMatch(mime)) {
        res.add(key);
      }
    });
    return res;
  }
}
