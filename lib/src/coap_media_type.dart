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
    textXml: <String>['text/xml', 'xml'],
    textCsv: <String>['text/csv', 'csv'],
    textHtml: <String>['text/html', 'html'],
    imageGif: <String>['image/gif', 'gif'],
    imageJpeg: <String>['image/jpeg', 'jpg'],
    imagePng: <String>['image/png', 'png'],
    imageTiff: <String>['image/tiff', 'tif'],
    audioRaw: <String>['audio/raw', 'raw'],
    videoRaw: <String>['video/raw', 'raw'],
    applicationLinkFormat: <String>['application/link-format', 'wlnk'],
    applicationXml: <String>['application/xml', 'xml'],
    applicationOctetStream: <String>['application/octet-stream', 'bin'],
    applicationRdfXml: <String>['application/rdf+xml', 'rdf'],
    applicationSoapXml: <String>['application/soap+xml', 'soap'],
    applicationAtomXml: <String>['application/atom+xml', 'atom'],
    applicationXmppXml: <String>['application/xmpp+xml', 'xmpp'],
    applicationFastinfoset: <String>['application/fastinfoset', 'finf'],
    applicationSoapFastinfoset: <String>[
      'application/soap+fastinfoset',
      'soap.finf'
    ],
    applicationXObixBinary: <String>['application/x-obix-binary', 'obix'],
    applicationExi: <String>['application/exi', 'exi'],
    applicationJson: <String>['application/json', 'json']
  };

  /// undefined
  static const int undefined = -1;

  /// text/plain; charset=utf-8
  static const int textPlain = 0;

  /// text/xml
  static const int textXml = 1;

  /// text/csv
  static const int textCsv = 2;

  /// text/html
  static const int textHtml = 3;

  /// image/gif
  static const int imageGif = 21;

  /// image/jpeg
  static const int imageJpeg = 22;

  /// image/png
  static const int imagePng = 23;

  /// image/tiff
  static const int imageTiff = 24;

  /// audio/raw
  static const int audioRaw = 25;

  /// video/raw
  static const int videoRaw = 26;

  /// application/link-format
  static const int applicationLinkFormat = 40;

  /// application/xml
  static const int applicationXml = 41;

  /// application/octet-stream
  static const int applicationOctetStream = 42;

  /// application/rdf+xml
  static const int applicationRdfXml = 43;

  /// application/soap+xml
  static const int applicationSoapXml = 44;

  /// application/atom+xml
  static const int applicationAtomXml = 45;

  /// application/xmpp+xml
  static const int applicationXmppXml = 46;

  /// application/exi
  static const int applicationExi = 47;

  /// application/fastinfoset
  static const int applicationFastinfoset = 48;

  /// application/soap+fastinfoset
  static const int applicationSoapFastinfoset = 49;

  /// application/json
  static const int applicationJson = 50;

  /// application/x-obix-binary
  static const int applicationXObixBinary = 51;

  /// any
  static const int any = 0xFF;

  /// Checks whether the given media type is a type of image.
  /// True iff the media type is a type of image.
  static bool isImage(int mediaType) =>
      mediaType >= imageGif && mediaType <= imageTiff;

  /// Is the media type printable
  static bool isPrintable(int mediaType) {
    switch (mediaType) {
      case textPlain:
      case textXml:
      case textCsv:
      case textHtml:
      case applicationLinkFormat:
      case applicationXml:
      case applicationRdfXml:
      case applicationSoapXml:
      case applicationAtomXml:
      case applicationXmppXml:
      case applicationJson:
      case undefined:
        return true;
        break;
      default:
        return false;
        break;
    }
  }

  /// Returns a string representation of the media type.
  static String name(int mediaType) {
    if (_registry.containsKey(mediaType)) {
      return _registry[mediaType][0];
    } else {
      return 'unknown/$mediaType';
    }
  }

  /// Gets the file extension of the given media type.
  static String fileExtension(int mediaType) {
    if (_registry.containsKey(mediaType)) {
      return _registry[mediaType][1];
    } else {
      return 'unknown/$mediaType';
    }
  }

  /// Negotiation content
  static int negotiationContent(
      int defaultContentType, List<int> supported, List<CoapOption> accepted) {
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
  static int parse(String type) {
    if (type == null) {
      return CoapMediaType.undefined;
    }
    int keyRet;
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
  static List<int> parseWildcard(String regex) {
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
