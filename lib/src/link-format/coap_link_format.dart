// ignore_for_file: avoid_classes_with_only_static_members

/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

import 'dart:collection';

import '../option/option.dart';
import '../util/coap_scanner.dart';
import 'coap_link_attribute.dart';
import 'coap_web_link.dart';
import 'resources/coap_endpoint_resource.dart';
import 'resources/coap_remote_resource.dart';
import 'resources/coap_resource.dart';
import 'resources/coap_resource_attributes.dart';

enum LinkFormatParameterType {
  // TODO(JKRhb): Revisit typing
  bool,
  string,
  uint;
}

enum LinkFormatParameter {
  /// Name of the attribute `Resource Type`.
  resourceType('rt'),

  /// Name of the attribute `Interface Description`.
  interfaceDescription('if'),

  /// Name of the attribute `Content Type`.
  contentType('ct', parameterType: LinkFormatParameterType.uint),

  /// Name of the attribute `Max Size Estimate`.
  maxSizeEstimate('sz', parameterType: LinkFormatParameterType.uint),

  /// Name of the attribute `Title`.
  title('title'),

  /// Name of the attribute `Observable`.
  ///
  /// Specified in [RFC 7641, section 6].
  ///
  /// [RFC 7641, section 6]: https://datatracker.ietf.org/doc/html/rfc7641#section-6
  observable('obs', parameterType: LinkFormatParameterType.bool),

  /// Name of the attribute `Endpoint name`.
  ///
  /// Specified in [RFC 9176, section 9.3].
  ///
  /// [RFC 9176, section 9.3]: https://datatracker.ietf.org/doc/html/rfc9176#section-9.3
  endpointName('ep'),

  /// Name of the attribute `Lifetime`.
  ///
  /// Specified in [RFC 9176, section 9.3].
  ///
  /// [RFC 9176, section 9.3]: https://datatracker.ietf.org/doc/html/rfc9176#section-9.3
  // TODO(JKRhb): This needs to be a value between 1 and 4294967295.
  lifetime('lt', parameterType: LinkFormatParameterType.uint),

  /// Name of the attribute `Sector`.
  ///
  /// Specified in [RFC 9176, section 9.3].
  ///
  /// [RFC 9176, section 9.3]: https://datatracker.ietf.org/doc/html/rfc9176#section-9.3
  sector('d'),

  /// Name of the attribute `Registration Base URI`.
  ///
  /// Specified in [RFC 9176, section 9.3].
  ///
  /// [RFC 9176, section 9.3]: https://datatracker.ietf.org/doc/html/rfc9176#section-9.3
  base('base'),

  /// Name of the attribute `Page`.
  ///
  /// Specified in [RFC 9176, section 9.3].
  ///
  /// [RFC 9176, section 9.3]: https://datatracker.ietf.org/doc/html/rfc9176#section-9.3
  page('page', parameterType: LinkFormatParameterType.uint),

  /// Name of the attribute `Count`.
  ///
  /// Specified in [RFC 9176, section 9.3].
  ///
  /// [RFC 9176, section 9.3]: https://datatracker.ietf.org/doc/html/rfc9176#section-9.3
  count('count', parameterType: LinkFormatParameterType.uint),

  /// Name of the attribute `Endpoint Type`.
  ///
  /// Specified in [RFC 9176, section 9.3].
  ///
  /// [RFC 9176, section 9.3]: https://datatracker.ietf.org/doc/html/rfc9176#section-9.3
  endpointType('et');

  const LinkFormatParameter(
    this.short, {
    final LinkFormatParameterType parameterType =
        LinkFormatParameterType.string,
  }) : _parameterType = parameterType;

  static final _registry = HashMap.fromEntries(
    values.map((final value) => MapEntry(value.short, value)),
  );

  static LinkFormatParameter? fromShort(final String short) => _registry[short];

  final String short;

  bool get isSingle => parameterType == LinkFormatParameterType.bool;

  final LinkFormatParameterType _parameterType;

  LinkFormatParameterType get parameterType => _parameterType;

  @override
  String toString() => short;
}

/// This class provides link format definitions as specified in RFC 6690.
class CoapLinkFormat {
  /// Name of the attribute link
  static const String link = 'href';

  /// The string as the delimiter between resources
  static const String delimiter = ',';

  /// The string to separate attributes
  static const String separator = ';';

  /// Link start marker
  static const String linkStart = '<';

  /// Attribute name/value separator
  static const String attrNameValueSeparator = '=';

  /// Supporting regular expressions

  /// Resource name
  static final RegExp resourceNameRegex = RegExp('<[^>]*>');

  /// Word
  static final RegExp wordRegex = RegExp(r'\w+');

  /// Quoted string
  static final RegExp quotedStringRegex = RegExp('".*?"');

  /// Cardinal
  static final RegExp cardinalRegex = RegExp(r'\d+');

  /// Equal
  static final RegExp equalRegex = RegExp('=');

  /// Serialize
  static String serialize(final CoapResource root) =>
      _serializeQueries(root, null);

  static String _serializeQueries(
    final CoapResource root,
    final Iterable<String>? queries,
  ) {
    final linkFormat = StringBuffer();

    for (final child in root.children!) {
      _serializeTree(child, queries, linkFormat);
    }
    var ret = linkFormat.toString();
    if (linkFormat.length > 1) {
      ret = ret.substring(0, linkFormat.length - 2);
    }
    return ret;
  }

  /// Parse
  static Iterable<CoapWebLink> parse(final String linkFormat) {
    final links = <CoapWebLink>[];
    if (linkFormat.isNotEmpty) {
      final scanner = CoapScanner(linkFormat);
      String? path;
      // Scan for paths
      while (scanner.scan(resourceNameRegex)) {
        final matched = scanner.lastMatch!;
        path = matched.group(0);
        path = path!.substring(1, path.length - 1);
        final link = CoapWebLink(path);
        links.add(link);
        // Check for the end of the link format string
        if (scanner.position == linkFormat.length) {
          break;
        }
        // Look for either a path or attribute delimiter
        final char = scanner.readChar();
        if (char == delimiter.codeUnitAt(0)) {
          // Next path
          continue;
        }
        if (char == separator.codeUnitAt(0)) {
          // Process attributes
          var attributeString = scanner.takeUntil(linkStart);

          // Condition the string before splitting
          if (attributeString.endsWith(delimiter)) {
            attributeString =
                attributeString.substring(0, attributeString.length - 1);
          } else {
            attributeString =
                attributeString.substring(0, attributeString.length);
          }
          // Split on delimiter
          final attrs = attributeString.split(separator);
          for (final attr in attrs) {
            final parts = attr.split(attrNameValueSeparator);
            if (parts.length == 1) {
              link.attributes.addNoValue(parts[0]);
            } else {
              link.attributes.add(parts[0], parts[1]);
            }
          }

          // Next path
          continue;
        }
      }
    }
    return links;
  }

  static void _serializeTree(
    final CoapResource resource,
    final Iterable<String>? queries,
    final StringBuffer sb,
  ) {
    if (resource.visible! && _matchesString(resource, queries)) {
      _serializeResource(resource, sb);
      sb.write(',');
    }
    // sort by resource name
    final children = resource.children! as List<CoapResource>
      ..sort(
        (final r1, final r2) => r1.name!.compareTo(r2.name!),
      );
    for (final child in children) {
      _serializeTree(child, queries, sb);
    }
  }

  static void _serializeResource(
    final CoapResource resource,
    final StringBuffer sb,
  ) {
    sb.write('<${resource.path}${resource.name}>');
    _serializeAttributes(resource.attributes!, sb);
  }

  static void _serializeAttributes(
    final CoapResourceAttributes attributes,
    final StringBuffer sb,
  ) {
    final keys = attributes.keys as List<String>..sort();
    for (final name in keys) {
      final values = attributes.getValues(name)! as List<String?>;
      if (values.isEmpty) {
        continue;
      }
      sb.write(separator);
      _serializeAttribute(name, values, sb);
    }
  }

  static void _serializeAttribute(
    final String name,
    final Iterable<String?> values,
    final StringBuffer sb,
  ) {
    sb.write(name);
    for (final value in values) {
      sb.write('="$value"');
    }
  }

  /// Serialize options
  static String serializeOptions(
    final CoapEndpointResource resource,
    final Iterable<Option<String>>? query, {
    required final bool recursive,
  }) {
    final linkFormat = StringBuffer();

    // Skip hidden and empty root in recursive mode,
    // always skip non-matching resources.
    if ((!resource.hidden && resource.name.isNotEmpty || !recursive) &&
        _matchesOption(resource, query)) {
      linkFormat.write('<${resource.path}>');

      // Reverse the attribute list to re-create the original
      final attrs = resource.attributes.toList().reversed.toList();
      for (final attr in attrs) {
        linkFormat.write(separator);
        attr.serialize(linkFormat);
      }
    }

    if (recursive) {
      for (final sub in resource.getSubResources()) {
        final next = serializeOptions(sub, query, recursive: true);

        if (next.isNotEmpty) {
          if (linkFormat.length > 3) {
            linkFormat.write(delimiter);
          }
          linkFormat.write(next);
        }
      }
    }

    return linkFormat.toString();
  }

  /// Deserialize
  static CoapRemoteResource deserialize(final String linkFormat) {
    final root = CoapRemoteResource('');
    final scanner = CoapScanner(linkFormat);
    while (scanner.scan(resourceNameRegex)) {
      final matched = scanner.lastMatch!;
      var path = matched.group(0)!;
      path = path.substring(1, path.length - 1);
      // Retrieve specified resource, create if necessary
      final resource = CoapRemoteResource(path);
      if (scanner.position == linkFormat.length) {
        root.addSubResource(resource);
        break;
      }
      while (scanner.readChar() == separator.codeUnitAt(0)) {
        final attr = parseAttribute(scanner);
        addAttribute(resource.attributes as HashSet<CoapLinkAttribute>, attr!);
        // ignore: invariant_booleans
        if (scanner.position == linkFormat.length) {
          break;
        }
      }
      root.addSubResource(resource);
    }
    return root;
  }

  /// Parse attribute
  static CoapLinkAttribute? parseAttribute(final CoapScanner scanner) {
    if (scanner.scan(wordRegex)) {
      final matched = scanner.lastMatch!;
      final name = matched.group(0);
      Object? value;
      value = true;
      // check for name-value-pair
      if (scanner.scan(equalRegex)) {
        if (scanner.matches(quotedStringRegex)) {
          scanner.scan(quotedStringRegex);
          final matched = scanner.lastMatch!;
          final s = matched.group(0)!;
          value = s.substring(1, s.length - 1);
        } else if (scanner.matches(cardinalRegex)) {
          scanner.scan(cardinalRegex);
          final matched = scanner.lastMatch!;
          final num = matched.group(0)!;
          value = int.tryParse(num);
          value ??= 0;
        } else {
          value = scanner.takeUntil(';');
        }
      }
      return CoapLinkAttribute(name!, value);
    }
    return null;
  }

  static bool _matchesOption(
    final CoapEndpointResource resource,
    final Iterable<Option<String>>? query,
  ) {
    if (query == null) {
      return true;
    }
    for (final q in query) {
      final s = q.value;
      final delim = s.indexOf('=');
      if (delim == -1) {
        // flag attribute
        if (resource.attributes.isNotEmpty) {
          return true;
        }
      } else {
        final attrName = s.substring(0, delim);
        var expected = s.substring(delim + 1);
        if (attrName == CoapLinkFormat.link) {
          if (expected.endsWith('*')) {
            return resource.path
                .startsWith(expected.substring(0, expected.length - 1));
          } else {
            return resource.path == expected;
          }
        }

        for (final attr in resource.getAttributes(attrName)) {
          var actual = attr.value.toString();
          // get prefix length according to '*'
          final prefixLength = expected.indexOf('*');
          if (prefixLength >= 0 && prefixLength < actual.length) {
            // reduce to prefixes
            expected = expected.substring(0, prefixLength);
            actual = actual.substring(0, prefixLength);
          }
          // handle case like rt=[Type1 Type2]
          if (actual.contains(' ')) {
            for (final part in actual.split(' ')) {
              if (part == expected) {
                return true;
              }
            }
          }
          if (expected == actual) {
            return true;
          }
        }
      }
    }
    return false;
  }

  static bool _matchesString(
    final CoapResource resource,
    final Iterable<String>? query,
  ) {
    if (query == null) {
      return true;
    }

    final attributes = resource.attributes;
    final path = resource.path! + resource.name!;
    if (query.isEmpty) {
      return true;
    }
    for (final ie in query) {
      final s = ie;

      final delim = s.indexOf('=');
      if (delim == -1) {
        // flag attribute
        if (attributes!.contains(s)) {
          return true;
        }
      } else {
        final attrName = s.substring(0, delim);
        var expected = s.substring(delim + 1);

        if (attrName == CoapLinkFormat.link) {
          if (expected.endsWith('*')) {
            return path.startsWith(expected.substring(0, expected.length - 1));
          } else {
            return path == expected;
          }
        } else if (attributes!.contains(attrName)) {
          // lookup attribute value
          for (final value in attributes.getValues(attrName)!) {
            var actual = value;
            // get prefix length according to '*'
            final prefixLength = expected.indexOf('*');
            if (prefixLength >= 0 && prefixLength < actual!.length) {
              // reduce to prefixes
              expected = expected.substring(0, prefixLength);
              actual = actual.substring(0, prefixLength);
            }

            // handle case like rt=[Type1 Type2]
            if (actual!.contains(' ')) {
              for (final part in actual.split(' ')) {
                if (part == expected) {
                  return true;
                }
              }
            }

            if (expected == actual) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  /// Add attribute
  static bool addAttribute(
    final HashSet<CoapLinkAttribute> attributes,
    final CoapLinkAttribute attrToAdd,
  ) {
    final parameter = LinkFormatParameter.fromShort(attrToAdd.name);

    if (parameter == null) {
      // Attribute is unknown
      return false;
    }

    if (parameter.isSingle &&
        attributes
            .map((final attribute) => attribute.name)
            .contains(attrToAdd.name)) {
      return false;
    }
    // Special rules
    if (parameter.parameterType == LinkFormatParameterType.uint &&
        attrToAdd.valueAsInt! < 0) {
      return false;
    }
    attributes.add(attrToAdd);
    return true;
  }
}
