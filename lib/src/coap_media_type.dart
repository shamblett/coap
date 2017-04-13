/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// This class describes the CoAP Media Type Registry as defined in
/// RFC 7252, Section 12.3.
class MediaType {
  static Map<int, List<String>> _registry = new Map<int, List<String>>();

  MediaType() {
    _registry[textPlain] = ["text/plain", "txt"];
    _registry[textXml] = ["text/xml", "xml"];
    _registry[textCsv] = ["text/csv", "csv"];
    _registry[textHtml] = ["text/html", "html"];
    _registry[imageGif] = ["image/gif", "gif"];
    _registry[imageJpeg] = ["image/jpeg", "jpg"];
    _registry[imagePng] = ["image/png", "png"];
    _registry[imageTiff] = ["image/tiff", "tif"];
    _registry[audioRaw] = ["audio/raw", "raw"];
    _registry[videoRaw] = ["video/raw", "raw"];
    _registry[applicationLinkFormat] = ["application/link-format", "wlnk"];
    _registry[applicationXml] = ["application/xml", "xml"];
    _registry[applicationOctetStream] = ["application/octet-stream", "bin"];
    _registry[applicationRdfXml] = ["application/rdf+xml", "rdf"];
    _registry[applicationSoapXml] = ["application/soap+xml", "soap"];
    _registry[applicationAtomXml] = ["application/atom+xml", "atom"];
    _registry[applicationXmppXml] = ["application/xmpp+xml", "xmpp"];
    _registry[applicationFastinfoset] = ["application/fastinfoset", "finf"];
    _registry[applicationSoapFastinfoset] = [
      "application/soap+fastinfoset",
      "soap.finf"
    ];
    _registry[applicationXObixBinary] = ["application/x-obix-binary", "obix"];
    _registry[applicationExi] = ["application/exi", "exi"];
    _registry[applicationJson] = ["application/json", "json"];
  }

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
  static bool isImage(int mediaType) {
    return mediaType >= imageGif && mediaType <= imageTiff;
  }

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
      return "unknown/" + mediaType.toString();
    }
  }

  /// Gets the file extension of the given media type.
  static String fileExtension(int mediaType) {
    if (_registry.containsKey(mediaType)) {
      return _registry[mediaType][1];
    } else {
      return "unknown/" + mediaType.toString();
    }
  }
}
