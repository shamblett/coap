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
    applicationJson: <String>['application/json', 'json'],
    // FIXME: How to deal with undefined file extensions?
    applicationJsonPatchJson: <String>['application/json-patch+json'],
    applicationMergePatchJson: <String>['application/merge-patch+json'],
    applicationCbor: <String>['application/cbor', 'cbor'],
    applicationCwt: <String>['application/cwt'],
    applicationMultipartCore: <String>['application/multipart-core'],
    applicationCborSeq: <String>['application/cbor-seq'],
    // TODO: Add application/cose Content Formats
    applicationCoseKey: <String>['application/cose-key', 'cbor'],
    applicationCoseKeySet: <String>['application/cose-key-set', 'cbor'],
    applicationSenmlJson: <String>['application/senml+json', 'senml'],
    applicationSensmlJson: <String>['application/sensml+json', 'sensml'],
    applicationSenmlCbor: <String>['application/senml+cbor', 'senmlc'],
    applicationSensmlCbor: <String>['application/sensml+cbor', 'sensmlc'],
    applicationSenmlExi: <String>['application/senml-exi', 'senmle'],
    applicationSensmlExi: <String>['application/sensml-exi', 'sensmle'],
    applicationCoapGroupJson: <String>['application/coap-group+json', 'json'],
    applicationDotsCbor: <String>['application/dots+cbor'],
    applicationMissingBlocksCborSeq: <String>[
      'application/missing-blocks+cbor-seq'
    ],
    // TODO: Add application/pkcs7-mime Content Formats
    applicationPkcs8: <String>['application/pkcs8'],
    applicationCsrattrs: <String>['application/csrattrs'],
    applicationPkcs10: <String>['application/pkcs10'],
    applicationPkixCert: <String>['application/pkix-cert'],
    applicationSenmlXml: <String>['application/senml+xml', 'senmlx'],
    applicationSensmlXml: <String>['application/sensml+xml', 'sensmlx'],
    applicationSenmlEtchJson: <String>[
      'application/senml-etch+json',
      'senml-etchj'
    ],
    applicationSenmlEtchCbor: <String>[
      'application/senml-etch+cbor',
      'senml-etchc'
    ],
    applicationTdJson: <String>['application/td+json', 'jsontd'],
    applicationVndOcfCbor: <String>['application/vnd.ocf+cbor'],
    applicationOscore: <String>['application/oscore'],
    applicationJavascript: <String>['application/javascript', 'js'],
    textCss: <String>['text/css', 'css'],
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

  /// application/json-patch+json
  static const int applicationJsonPatchJson = 51;

  /// application/merge-patch+json
  static const int applicationMergePatchJson = 52;

  /// application/cbor
  static const int applicationCbor = 60;

  /// application/cwt
  static const int applicationCwt = 61;

  /// application/multipart-core
  static const int applicationMultipartCore = 62;

  /// application/cbor-seq
  static const int applicationCborSeq = 63;

  /// application/cose-key
  static const int applicationCoseKey = 101;

  /// application/cose-key-set
  static const int applicationCoseKeySet = 102;

  /// application/senml+json
  static const int applicationSenmlJson = 110;

  /// application/sensml+json
  static const int applicationSensmlJson = 111;

  /// application/senml+cbor
  static const int applicationSenmlCbor = 112;

  /// application/sensml+cbor
  static const int applicationSensmlCbor = 113;

  /// application/senml-exi
  static const int applicationSenmlExi = 114;

  /// application/sensml-exi
  static const int applicationSensmlExi = 115;

  /// application/coap-group+json
  static const int applicationCoapGroupJson = 256;

  /// application/dots+cbor
  static const int applicationDotsCbor = 271;

  /// application/missing-blocks+cbor-seq
  static const int applicationMissingBlocksCborSeq = 272;

  /// application/pkcs8
  static const int applicationPkcs8 = 284;

  /// application/csrattrs
  static const int applicationCsrattrs = 285;

  /// application/pkcs10
  static const int applicationPkcs10 = 286;

  /// application/pkix-cert
  static const int applicationPkixCert = 287;

  /// application/senml+xml
  static const int applicationSenmlXml = 310;

  /// application/sensml+xml
  static const int applicationSensmlXml = 311;

  /// application/senml-etch+json
  static const int applicationSenmlEtchJson = 320;

  /// application/senml-etch+cbor
  static const int applicationSenmlEtchCbor = 322;

  /// application/td+json
  static const int applicationTdJson = 432;

  /// application/vnd.ocf+cbor
  static const int applicationVndOcfCbor = 10000;

  /// application/oscore
  static const int applicationOscore = 10001;

  /// application/javascript
  static const int applicationJavascript = 10002;

  /// text/css
  static const int textCss = 20000;

  /// image/svg+xml
  static const int imageSvgXml = 30000;

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
  ///
  /// Returns 'application/octet-stream' as the default if the [mediaType] code
  /// is unknown.
  static String name(int mediaType) {
    if (_registry.containsKey(mediaType)) {
      return _registry[mediaType]![0];
    } else {
      return 'application/octet-stream';
    }
  }

  /// Gets the file extension of the given media type.
  ///
  /// Returns 'undefined' if the [mediaType] cannot be resolved.
  static String fileExtension(int mediaType) {
    if (_registry.containsKey(mediaType) && _registry[mediaType]!.length > 1) {
      return _registry[mediaType]![1];
    }

    return 'undefined';
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
