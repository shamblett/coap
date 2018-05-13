/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 31/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// This class provides link format definitions as specified in
/// draft-ietf-core-link-format-06
class CoapLinkFormat {
  /// Name of the attribute Resource Type
  static const String resourceType = "rt";

  /// Name of the attribute Interface Description
  static const String interfaceDescription = "if";

  /// Name of the attribute Content Type
  static const String contentType = "ct";

  /// Name of the attribute Max Size Estimate
  static const String maxSizeEstimate = "sz";

  /// Name of the attribute Title
  static const String title = "title";

  /// Name of the attribute Observable
  static const String observable = "obs";

  /// Name of the attribute link
  static const String link = "href";

  /// The string as the delimiter between resources
  static const String delimiter = ",";

  /// The string to separate attributes
  static const String separator = ";";

  /// Supporting regular expressions
  static final RegExp delimiterRegex = new RegExp("\\s*" + delimiter + "+\\s*");
  static final RegExp separatorRegex = new RegExp("\\s*" + separator + "+\\s*");
  static final RegExp resourceNameRegex = new RegExp("<[^>]*>");
  static final RegExp wordRegex = new RegExp("\\w+");
  static final RegExp quotedStringRegex = new RegExp("\".*?\"");
  static final RegExp cardinalRegex = new RegExp("\\d+");
  static final RegExp _equalRegex = new RegExp("=");

  static CoapILogger _log = new CoapLogManager("console").logger;

  static String serialize(CoapIResource root) {
    return _serializeQueries(root, null);
  }

  static String _serializeQueries(CoapIResource root,
      Iterable<String> queries) {
    final StringBuffer linkFormat = new StringBuffer();

    for (CoapIResource child in root.children) {
      _serializeTree(child, queries, linkFormat);
    }
    String ret = linkFormat.toString();
    if (linkFormat.length > 1) {
      ret = ret.substring(0, linkFormat.length - 2);
    }
    return ret;
  }

  static Iterable<CoapWebLink> parse(String linkFormat) sync* {
    if (linkFormat.isNotEmpty) {
      final CoapScanner scanner = new CoapScanner(linkFormat);
      String path = null;
      while ((path = scanner.find(resourceNameRegex)) != null) {
        path = path.substring(1, path.length - 2);
        final CoapWebLink link = new CoapWebLink(path);

        String attr = null;
        while (scanner.find(delimiterRegex) == null &&
            (attr = scanner.find(wordRegex)) != null) {
          if (scanner.find(_equalRegex) == null) {
            // flag attribute without value
            link.attributes.addNoValue(attr);
          } else {
            String value = null;
            if ((value = scanner.findFirstExact(quotedStringRegex)) != null) {
              // trim " "
              value = value.substring(1, value.length - 2);
              if (title == attr) {
                link.attributes.add(attr, value);
              } else {
                for (String part in value.split("\\")) {
                  link.attributes.add(attr, part);
                }
              }
            } else if ((value = scanner.find(wordRegex)) != null) {
              link.attributes.set(attr, value);
            } else if ((value = scanner.findFirstExact(cardinalRegex)) !=
                null) {
              link.attributes.set(attr, value);
            }
          }
        }
        yield link;
      }
    }
  }

  static void _serializeTree(CoapIResource resource, Iterable<String> queries,
      StringBuffer sb) {
    if (resource.visible && _matchesString(resource, queries)) {
      _serializeResource(resource, sb);
      sb.write(",");
    }
    // sort by resource name
    final List<CoapIResource> children = resource.children;
    children.sort(
            (CoapIResource r1, CoapIResource r2) => r1.name.compareTo(r2.name));
    for (CoapIResource child in children) {
      _serializeTree(child, queries, sb);
    }
  }

  static void _serializeResource(CoapIResource resource, StringBuffer sb) {
    sb.write("<");
    sb.write(resource.path);
    sb.write(resource.name);
    sb.write(">");
    _serializeAttributes(resource.attributes, sb);
  }

  static void _serializeAttributes(CoapResourceAttributes attributes,
      StringBuffer sb) {
    final List<String> keys = attributes.keys;
    keys.sort();
    for (String name in keys) {
      final List<String> values = attributes.getValues(name);
      if (values.length == 0) continue;
      sb.write(separator);
      _serializeAttribute(name, values, sb);
    }
  }

  static void _serializeAttribute(String name, Iterable<String> values,
      StringBuffer sb) {
    final String delimiter = "=";
    sb.write(name);
    for (String value in values) {
      sb.write(delimiter);
      sb.write('"');
      sb.write(value);
      sb.write('"');
    }
  }

  static String serializeOptions(CoapEndpointResource resource,
      Iterable<CoapOption> query, bool recursive) {
    final StringBuffer linkFormat = new StringBuffer();

    // skip hidden and empty root in recursive mode, always skip non-matching resources
    if ((!resource.hidden && (resource.name.length > 0) || !recursive) &&
        _matchesOption(resource, query)) {
      linkFormat.write("<");
      linkFormat.write(resource.path);
      linkFormat.write(">");

      // Reverse the attribute list to re-create the original
      final List<CoapLinkAttribute> attrs =
      resource.attributes
          .toList()
          .reversed
          .toList();
      for (CoapLinkAttribute attr in attrs) {
        linkFormat.write(separator);
        attr.serialize(linkFormat);
      }
    }

    if (recursive) {
      for (CoapEndpointResource sub in resource.getSubResources()) {
        final String next = serializeOptions(sub, query, true);

        if (next.length > 0) {
          if (linkFormat.length > 3) linkFormat.write(delimiter);
          linkFormat.write(next);
        }
      }
    }

    return linkFormat.toString();
  }

  static CoapRemoteResource deserialize(String linkFormat) {
    final CoapRemoteResource root = new CoapRemoteResource("");
    final CoapScanner scanner = new CoapScanner(linkFormat);
    String path;
    while ((path = scanner.find(resourceNameRegex)) != null) {
      path = path.substring(1, path.length - 1);
      // Retrieve specified resource, create if necessary
      final CoapRemoteResource resource = new CoapRemoteResource(path);
      CoapLinkAttribute attr = null;
      while (scanner.findHorizon(delimiterRegex, 1) == null &&
          (attr = parseAttribute(scanner)) != null) {
        addAttribute(resource.attributes, attr);
      }
      root.addSubResource(resource);
    }
    return root;
  }

  static CoapLinkAttribute parseAttribute(CoapScanner scanner) {
    final String name = scanner.find(wordRegex);
    if (name == null)
      return null;
    else {
      Object value;
      value = true;
      // check for name-value-pair
      if (scanner.find(_equalRegex) == null)
        // flag attribute
        value = true;
      else {
        String s = null;
        if ((s = scanner.findFirstExact(quotedStringRegex)) != null)
          // trim " "
          value = s.substring(1, s.length - 1);
        else if ((s = scanner.findFirstExact(cardinalRegex)) != null)
          value = int.parse(s);
      }
      return new CoapLinkAttribute(name, value);
    }
  }

  static bool _matchesOption(CoapEndpointResource resource,
      Iterable<CoapOption> query) {
    if (resource == null) return false;
    if (query == null) return true;
    for (CoapOption q in query) {
      final String s = q.stringValue;
      final int delim = s.indexOf('=');
      if (delim == -1) {
        // flag attribute
        if (resource.attributes.length > 0) return true;
      } else {
        final String attrName = s.substring(0, delim);
        String expected = s.substring(delim + 1);
        if (attrName == CoapLinkFormat.link) {
          if (expected.endsWith("*"))
            return resource.path
                .startsWith(expected.substring(0, expected.length - 1));
          else
            return resource.path == expected;
        }

        for (CoapLinkAttribute attr in resource.getAttributes(attrName)) {
          String actual = attr.value.toString();
          // get prefix length according to "*"
          final int prefixLength = expected.indexOf('*');
          if (prefixLength >= 0 && prefixLength < actual.length) {
            // reduce to prefixes
            expected = expected.substring(0, prefixLength);
            actual = actual.substring(0, prefixLength);
          }
          // handle case like rt=[Type1 Type2]
          if (actual.indexOf(' ') > -1) {
            for (String part in actual.split(' ')) {
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
    if (resource == null) return false;
    if (query == null) return true;

    final CoapResourceAttributes attributes = resource.attributes;
    final String path = resource.path + resource.name;
    if (query.isEmpty) {
      return true;
    }
    for (String ie in query) {
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
          if (expected.endsWith("*")) {
            return path.startsWith(expected.substring(0, expected.length - 1));
          } else {
            return path == expected;
          }
        } else if (attributes.contains(attrName)) {
          // lookup attribute value
          for (String value in attributes.getValues(attrName)) {
            String actual = value;
            // get prefix length according to "*"
            final int prefixLength = expected.indexOf('*');
            if (prefixLength >= 0 && prefixLength < actual.length) {
              // reduce to prefixes
              expected = expected.substring(0, prefixLength);
              actual = actual.substring(0, prefixLength);
            }

            // handle case like rt=[Type1 Type2]
            if (actual.indexOf(' ') > -1) {
              for (String part in actual.split(' ')) {
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

  static bool addAttribute(HashSet<CoapLinkAttribute> attributes,
      CoapLinkAttribute attrToAdd) {
    if (isSingle(attrToAdd.name)) {
      for (CoapLinkAttribute attr in attributes) {
        if (attr.name == attrToAdd.name) {
          _log.debug(
              "CoapLinkFormat::addAttribute - Found existing singleton attribute: " +
                  attr.name);
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

  static bool isSingle(String name) {
    return name == title || name == maxSizeEstimate || name == observable;
  }
}
