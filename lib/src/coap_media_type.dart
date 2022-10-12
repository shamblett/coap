/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 12/04/2017
 * Copyright :  S.Hamblett
 */

import 'dart:collection';
import 'dart:io';
import 'package:collection/collection.dart';

/// This enum describes the CoAP Media Type Registry as defined in
/// RFC 7252, Section 12.3.
enum CoapMediaType {
  /// text/plain; charset=utf-8
  textPlain(0, 'text', 'plain', charset: 'utf-8'),

  /// application/cose; cose-type="cose-encrypt0"
  applicationCoseCoseTypeCoseEncrypt0(
    16,
    'application',
    'cose',
    parameters: {'cose-type': 'cose-encrypt0'},
  ),

  /// application/cose; cose-type="cose-mac0"
  applicationCoseCoseTypeCoseMac0(
    17,
    'application',
    'cose',
    parameters: {'cose-type': 'cose-mac0'},
  ),

  /// application/cose; cose-type="cose-sign1"
  applicationCoseCoseTypeCoseSign1(
    18,
    'application',
    'cose',
    parameters: {'cose-type': 'cose-sign1'},
  ),

  /// image/gif
  applicationAceCbor(19, 'application', 'ace+cbor'),

  /// image/gif
  imageGif(21, 'image', 'gif'),

  /// image/jpeg
  imageJpeg(22, 'image', 'jpeg'),

  /// image/png
  imagePng(23, 'image', 'png'),

  /// application/link-format
  applicationLinkFormat(
    40,
    'application',
    'link-format',
  ),

  /// application/xml
  applicationXml(41, 'application', 'xml'),

  /// application/octet-stream
  applicationOctetStream(
    42,
    'application',
    'octet-stream',
  ),

  /// application/exi
  applicationExi(47, 'application', 'exi'),

  /// application/json
  applicationJson(50, 'application', 'json'),

  /// application/json-patch+json
  applicationJsonPatchJson(51, 'application', 'json-patch+json'),

  /// application/merge-patch+json
  applicationMergePatchJson(52, 'application', 'merge-patch+json'),

  /// application/cbor
  applicationCbor(60, 'application', 'cbor'),

  /// application/cwt
  applicationCwt(61, 'application', 'cwt'),

  /// application/multipart-core
  applicationMultipartCore(62, 'application', 'multipart-core'),

  /// application/cbor-seq
  applicationCborSeq(63, 'application', 'cbor-seq'),

  /// application/cose; cose-type="cose-encrypt"
  applicationCoseCoseTypeCoseEncrypt(
    96,
    'application',
    'cose',
    parameters: {'cose-type': 'cose-encrypt'},
  ),

  /// application/cose; cose-type="cose-mac"
  applicationCoseCoseTypeCoseMac(
    97,
    'application',
    'cose',
    parameters: {'cose-type': 'cose-mac'},
  ),

  /// application/cose; cose-type="cose-sign"
  applicationCoseCoseTypeCoseSign(
    98,
    'application',
    'cose',
    parameters: {'cose-type': 'cose-sign'},
  ),

  /// application/cose-key
  applicationCoseKey(101, 'application', 'cose-key'),

  /// application/cose-key-set
  applicationCoseKeySet(102, 'application', 'cose-key-set'),

  /// application/senml+json
  applicationSenmlJson(110, 'application', 'senml+json'),

  /// application/sensml+json
  applicationSensmlJson(111, 'application', 'sensml+json'),

  /// application/senml+cbor
  applicationSenmlCbor(112, 'application', 'senml+cbor'),

  /// application/sensml+cbor
  applicationSensmlCbor(113, 'application', 'sensml+cbor'),

  /// application/senml-exi
  applicationSenmlExi(114, 'application', 'senml-exi'),

  /// application/sensml-exi
  applicationSensmlExi(115, 'application', 'sensml-exi'),

  /// application/yang-data+cbor; id=sid
  applicationYangDataCborSid(
    140,
    'application',
    'sensml-exi',
    parameters: {'id': 'sid'},
  ),

  /// application/coap-group+json
  applicationCoapGroupJson(256, 'application', 'coap-group+json'),

  /// Content-Format for Media-Type `application/concise-problem-details+cbor`.
  ///
  /// Defined in [RFC-ietf-core-problem-details-08].
  ///
  /// [RFC-ietf-core-problem-details-08]: https://datatracker.ietf.org/doc/html/draft-ietf-core-problem-details-08
  applicationConciseProblemDetailsCbor(
    257,
    'application',
    'concise-problem-details+cbor',
  ),

  /// application/dots+cbor
  applicationDotsCbor(271, 'application', 'dots+cbor'),

  /// application/missing-blocks+cbor-seq
  applicationMissingBlocksCborSeq(
    272,
    'application',
    'missing-blocks+cbor-seq',
  ),

  /// application/pkcs7-mime; smime-type=server-generated-key
  applicationPkcs7MimeServerGeneratedKey(
    280,
    'application',
    'pkcs7-mime',
    parameters: {'mime-type': 'server-generated-key'},
  ),

  /// application/pkcs7-mime; smime-type=certs-only
  applicationPkcs7MimeCertsOnly(
    281,
    'application',
    'pkcs7-mime',
    parameters: {'mime-type': 'certs-only'},
  ),

  /// application/pkcs8
  applicationPkcs8(284, 'application', 'pkcs8'),

  /// application/csrattrs
  applicationCsrattrs(285, 'application', 'csrattrs'),

  /// application/pkcs10
  applicationPkcs10(286, 'application', 'pkcs10'),

  /// application/pkix-cert
  applicationPkixCert(287, 'application', 'pkix-cert'),

  /// application/aif+cbor
  applicationAifCbor(290, 'application', 'aif+cbor'),

  /// application/aif+json
  applicationAifJson(291, 'application', 'aif+json'),

  /// application/senml+xml
  applicationSenmlXml(310, 'application', 'senml+xml'),

  /// application/sensml+xml
  applicationSensmlXml(311, 'application', 'sensml+xml'),

  /// application/senml-etch+json
  applicationSenmlEtchJson(320, 'application', 'senml-etch+json'),

  /// application/senml-etch+cbor
  applicationSenmlEtchCbor(322, 'application', 'senml-etch+cbor'),

  /// application/yang-data+cbor
  applicationYangCbor(340, 'application', 'yang-data+cbor'),

  /// application/yang-data+cbor
  applicationSenmlEtchCborIdName(
    341,
    'application',
    'senml-etch+cbor',
    parameters: {'id': 'name'},
  ),

  /// application/td+json
  applicationTdJson(432, 'application', 'td+json'),

  /// Content-Format for Media-Type `application/tm+json`.
  ///
  /// Defined in [Web of Things (WoT) Thing Description 1.1].
  ///
  /// [Web of Things (WoT) Thing Description 1.1]: https://www.w3.org/TR/wot-thing-description11/
  applicationTmJson(433, 'application', 'tm+json'),

  /// application/voucher-cose+cbor
  applicationVoucerCoseCbor(836, 'application', 'voucher-cose+cbor'),

  /// application/vnd.ocf+cbor
  applicationVndOcfCbor(10000, 'application', 'vnd.ocf+cbor'),

  /// application/oscore
  applicationOscore(10001, 'application', 'oscore'),

  /// application/javascript
  applicationJavascript(10002, 'application', 'javascript'),

  /// application/json@deflate
  applictionJsonDeflate(11050, 'application', 'json', encoding: 'deflate'),

  /// application/cbor@deflate
  applictionCborDeflate(11060, 'application', 'cbor', encoding: 'deflate'),

  /// application/textCss
  textCss(20000, 'text', 'css'),

  /// application/svg+xml
  imageSvgXml(30000, 'image', 'svg+xml'),
  ;

  const CoapMediaType(
    this.numericValue,
    this.primaryType,
    this.subType, {
    this.charset,
    this.parameters = const {},
    this.encoding,
  });

  final int numericValue;

  String get mimeType => '$primaryType/$subType';

  final String primaryType;

  final String subType;

  final String? charset;

  final Map<String, String?> parameters;

  final String? encoding;

  ContentType get contentType => ContentType(
        primaryType,
        subType,
        charset: charset,
        parameters: parameters,
      );

  static final _registry = HashMap.fromEntries(
    values.map(
      (final contentFormat) =>
          MapEntry(contentFormat.numericValue, contentFormat),
    ),
  );

  static CoapMediaType? fromIntValue(final int value) => _registry[value];

  /// Parses a string-based contentType [value] and [encoding] and returns
  /// a [CoapMediaType], if a match has been found.
  ///
  /// Otherwise, it returns `null`.
  static CoapMediaType? parse(final String value, [final String? encoding]) {
    final contentType = ContentType.parse(value);

    return CoapMediaType.values.firstWhereOrNull(
      (final element) =>
          element.contentType.toString() == contentType.toString() &&
          element.encoding == encoding,
    );
  }

  /// Indicates if this [CoapMediaType] is printable.
  // TODO(JKRhb): Are there any uncovered cases?
  bool get isPrintable =>
      primaryType == 'text' ||
      subType.endsWith('xml') ||
      subType.endsWith('json') ||
      this == applicationLinkFormat ||
      this == applicationJavascript;

  /// Checks whether the given media type is a type of image.
  /// True iff the media type is a type of image.
  bool get isImage => primaryType == 'image';

  /// Formats the Content Encoding as described in [RFC 9193, section 3].
  ///
  /// [RFC 9193, section 3]:  https://datatracker.ietf.org/doc/html/rfc9193#section-3
  String get _formattedEncoding {
    if (encoding == null) {
      return '';
    }

    return '@$encoding';
  }

  @override
  String toString() => contentType.toString() + _formattedEncoding;
}
