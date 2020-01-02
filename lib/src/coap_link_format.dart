/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

// ignore_for_file: omit_local_variable_types
// ignore_for_file: unnecessary_final
// ignore_for_file: cascade_invocations
// ignore_for_file: avoid_print
// ignore_for_file: avoid_types_on_closure_parameters
// ignore_for_file: avoid_returning_this
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

// ignore: avoid_classes_with_only_static_members
/// This class provides link format definitions as specified in
/// draft-ietf-core-link-format-06
class CoapLinkFormat {
  /// Name of the attribute Resource Type
  static const String resourceType = 'rt';

  /// Name of the attribute Interface Description
  static const String interfaceDescription = 'if';

  /// Name of the attribute Content Type
  static const String contentType = 'ct';

  /// Name of the attribute Max Size Estimate
  static const String maxSizeEstimate = 'sz';

  /// Name of the attribute Title
  static const String title = 'title';

  /// Name of the attribute Observable
  static const String observable = 'obs';

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
  static final RegExp wordRegex = RegExp('\\w+');

  /// Quoted string
  static final RegExp quotedStringRegex = RegExp('\".*?\"');

  /// Cardinal
  static final RegExp cardinalRegex = RegExp('\\d+');

  /// Equal
  static final RegExp equalRegex = RegExp('=');

  static final CoapILogger _log = CoapLogManager().logger;

  /// Serialize
  static String serialize(CoapIResource root) => _serializeQueries(root, null);

  static String _serializeQueries(
      CoapIResource root, Iterable<String> queries) {
    final StringBuffer linkFormat = StringBuffer();

    for (final CoapIResource child in root.children) {
      _serializeTree(child, queries, linkFormat);
    }
    String ret = linkFormat.toString();
    if (linkFormat.length > 1) {
      ret = ret.substring(0, linkFormat.length - 2);
    }
    return ret;
  }

  /// Parse
  static Iterable<CoapWebLink> parse(String linkFormat) {
    final List<CoapWebLink> links = <CoapWebLink>[];
    if (linkFormat.isNotEmpty) {
      final CoapScanner scanner = CoapScanner(linkFormat);
      String path;
      // Scan for paths
      while (scanner.scan(resourceNameRegex)) {
        final Match matched = scanner.lastMatch;
        path = matched.group(0);
        path = path.substring(1, path.length - 1);
        final CoapWebLink link = CoapWebLink(path);
        links.add(link);
        // Check for the end of the link format string
        if (scanner.position == linkFormat.length) {
          break;
        }
        // Look for either a path or attribute delimiter
        final int char = scanner.readChar();
        if (char == delimiter.codeUnitAt(0)) {
          // Next path
          continue;
        }
        if (char == separator.codeUnitAt(0)) {
          // Process attributes
          String attributeString = scanner.takeUntil(linkStart);
          if (attributeString != null) {
            // Condition the string before splitting
            if (attributeString.endsWith(delimiter)) {
              attributeString =
                  attributeString.substring(0, attributeString.length - 1);
            } else {
              attributeString =
                  attributeString.substring(0, attributeString.length);
            }
            // Split on delimiter
            final List<String> attrs = attributeString.split(separator);
            for (final String attr in attrs) {
              final List<String> parts = attr.split(attrNameValueSeparator);
              if (parts.length == 1) {
                link.attributes.addNoValue(parts[0]);
              } else {
                link.attributes.add(parts[0], parts[1]);
              }
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
      CoapIResource resource, Iterable<String> queries, StringBuffer sb) {
    if (resource.visible && _matchesString(resource, queries)) {
      _serializeResource(resource, sb);
      sb.write(',');
    }
    // sort by resource name
    final List<CoapIResource> children = resource.children;
    children.sort(
        (CoapIResource r1, CoapIResource r2) => r1.name.compareTo(r2.name));
    for (final CoapIResource child in children) {
      _serializeTree(child, queries, sb);
    }
  }

  static void _serializeResource(CoapIResource resource, StringBuffer sb) {
    sb.write('<');
    sb.write(resource.path);
    sb.write(resource.name);
    sb.write('>');
    _serializeAttributes(resource.attributes, sb);
  }

  static void _serializeAttributes(
      CoapResourceAttributes attributes, StringBuffer sb) {
    final List<String> keys = attributes.keys;
    keys.sort();
    for (final String name in keys) {
      final List<String> values = attributes.getValues(name);
      if (values.isEmpty) {
        continue;
      }
      sb.write(separator);
      _serializeAttribute(name, values, sb);
    }
  }

  static void _serializeAttribute(
      String name, Iterable<String> values, StringBuffer sb) {
    const String delimiter = '=';
    sb.write(name);
    for (final String value in values) {
      sb.write(delimiter);
      sb.write('"');
      sb.write(value);
      sb.write('"');
    }
  }

  /// Serialize options
  static String serializeOptions(
      CoapEndpointResource resource, Iterable<CoapOption> query,
      {bool recursive}) {
    final StringBuffer linkFormat = StringBuffer();

    // Skip hidden and empty root in recursive mode,
    // always skip non-matching resources.
    if ((!resource.hidden && (resource.name.isNotEmpty) || !recursive) &&
        _matchesOption(resource, query)) {
      linkFormat.write('<');
      linkFormat.write(resource.path);
      linkFormat.write('>');

      // Reverse the attribute list to re-create the original
      final List<CoapLinkAttribute> attrs =
          resource.attributes.toList().reversed.toList();
      for (final CoapLinkAttribute attr in attrs) {
        linkFormat.write(separator);
        attr.serialize(linkFormat);
      }
    }

    if (recursive) {
      for (final CoapEndpointResource sub in resource.getSubResources()) {
        final String next = serializeOptions(sub, query, recursive: true);

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
  static CoapRemoteResource deserialize(String linkFormat) {
    final CoapRemoteResource root = CoapRemoteResource('');
    final CoapScanner scanner = CoapScanner(linkFormat);
    while (scanner.scan(resourceNameRegex)) {
      final Match matched = scanner.lastMatch;
      String path = matched.group(0);
      path = path.substring(1, path.length - 1);
      // Retrieve specified resource, create if necessary
      final CoapRemoteResource resource = CoapRemoteResource(path);
      if (scanner.position == linkFormat.length) {
        root.addSubResource(resource);
        break;
      }
      CoapLinkAttribute attr;
      while (scanner.readChar() == separator.codeUnitAt(0)) {
        attr = parseAttribute(scanner);
        addAttribute(resource.attributes, attr);
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
  static CoapLinkAttribute parseAttribute(CoapScanner scanner) {
    if (scanner.scan(wordRegex)) {
      final Match matched = scanner.lastMatch;
      final String name = matched.group(0);
      Object value;
      value = true;
      // check for name-value-pair
      if (!scanner.scan(equalRegex)) {
        // Flag attribute
        value = true;
      } else {
        if (scanner.matches(quotedStringRegex)) {
          scanner.scan(quotedStringRegex);
          final Match matched = scanner.lastMatch;
          final String s = matched.group(0);
          value = s.substring(1, s.length - 1);
        } else if (scanner.matches(cardinalRegex)) {
          scanner.scan(cardinalRegex);
          final Match matched = scanner.lastMatch;
          final String num = matched.group(0);
          value = int.tryParse(num);
          value ??= 0;
        }
      }
      return CoapLinkAttribute(name, value);
    }
    return null;
  }

  static bool _matchesOption(
      CoapEndpointResource resource, Iterable<CoapOption> query) {
    if (resource == null) {
      return false;
    }
    if (query == null) {
      return true;
    }
    for (final CoapOption q in query) {
      final String s = q.stringValue;
      final int delim = s.indexOf('=');
      if (delim == -1) {
        // flag attribute
        if (resource.attributes.isNotEmpty) {
          return true;
        }
      } else {
        final String attrName = s.substring(0, delim);
        String expected = s.substring(delim + 1);
        if (attrName == CoapLinkFormat.link) {
          if (expected.endsWith('*')) {
            return resource.path
                .startsWith(expected.substring(0, expected.length - 1));
          } else {
            return resource.path == expected;
          }
        }

        for (final CoapLinkAttribute attr in resource.getAttributes(attrName)) {
          String actual = attr.value.toString();
          // get prefix length according to '*'
          final int prefixLength = expected.indexOf('*');
          if (prefixLength >= 0 && prefixLength < actual.length) {
            // reduce to prefixes
            expected = expected.substring(0, prefixLength);
            actual = actual.substring(0, prefixLength);
          }
          // handle case like rt=[Type1 Type2]
          if (actual.contains(' ')) {
            for (final String part in actual.split(' ')) {
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

  static bool _matchesString(CoapIResource resource, Iterable<String> query) {
    if (resource == null) {
      return false;
    }
    if (query == null) {
      return true;
    }

    final CoapResourceAttributes attributes = resource.attributes;
    final String path = resource.path + resource.name;
    if (query.isEmpty) {
      return true;
    }
    for (final String ie in query) {
      final String s = ie;

      final int delim = s.indexOf('=');
      if (delim == -1) {
        // flag attribute
        if (attributes.contains(s)) {
          return true;
        }
      } else {
        final String attrName = s.substring(0, delim);
        String expected = s.substring(delim + 1);

        if (attrName == CoapLinkFormat.link) {
          if (expected.endsWith('*')) {
            return path.startsWith(expected.substring(0, expected.length - 1));
          } else {
            return path == expected;
          }
        } else if (attributes.contains(attrName)) {
          // lookup attribute value
          for (final String value in attributes.getValues(attrName)) {
            String actual = value;
            // get prefix length according to '*'
            final int prefixLength = expected.indexOf('*');
            if (prefixLength >= 0 && prefixLength < actual.length) {
              // reduce to prefixes
              expected = expected.substring(0, prefixLength);
              actual = actual.substring(0, prefixLength);
            }

            // handle case like rt=[Type1 Type2]
            if (actual.contains(' ')) {
              for (final String part in actual.split(' ')) {
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
      HashSet<CoapLinkAttribute> attributes, CoapLinkAttribute attrToAdd) {
    if (isSingle(attrToAdd.name)) {
      for (final CoapLinkAttribute attr in attributes) {
        if (attr.name == attrToAdd.name) {
          _log.warn(
              'CoapLinkFormat::addAttribute - Found existing '
                  'singleton attribute: ${attr.name}');
          return false;
        }
      }
    }
    // Special rules
    if ((attrToAdd.name == contentType) && (attrToAdd.valueAsInt < 0)) {
      return false;
    }
    if ((attrToAdd.name == maxSizeEstimate) && (attrToAdd.valueAsInt < 0)) {
      return false;
    }
    attributes.add(attrToAdd);
    return true;
  }

  /// Single
  static bool isSingle(String name) =>
      name == title || name == maxSizeEstimate || name == observable;
}
