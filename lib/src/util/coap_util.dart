/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 26/10/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// Utility methods
class CoapUtil {
  /// Stringify options in a message.
  static String optionsToString(CoapMessage msg) {
    final sb = StringBuffer();
    sb.writeln('[');
    sb.write(optionString('If-Match', msg.ifMatches));
    sb.write(optionString('Uri Host', msg.uriHost));
    sb.write(optionString('E-tags', msg.etags));
    sb.write(optionString('If-None Match', msg.ifNoneMatches));
    sb.write(optionString('Uri Port', msg.uriPort > 0 ? msg.uriPort : null));
    sb.write(optionString('Location Paths', msg.locationPaths));
    sb.write(optionString('Uri Paths', msg.uriPathsString));
    sb.write(optionString('Content-Type', CoapMediaType.name(msg.contentType)));
    sb.write(optionString('Max Age', msg.maxAge));
    sb.write(optionString('Uri Queries', msg.uriQueries));
    if (msg.accept != CoapMediaType.undefined) {
      sb.write(optionString('Accept', CoapMediaType.name(msg.accept)));
    }
    sb.write(optionString('Location Queries', msg.locationQueries));
    sb.write(optionString('Proxy Uri', msg.proxyUri));
    sb.write(optionString('Proxy Scheme', msg.proxyScheme));
    sb.write(optionString('Block 1', msg.block1));
    sb.write(optionString('Block 2', msg.block2));
    sb.write(optionString('Observe', msg.observe));
    sb.write(optionString('Size 1', msg.size1));
    sb.write(optionString('Size 2', msg.size2));
    sb.write(']');
    return sb.toString();
  }

  static String optionString(String name, Object? value) {
    if (value == null) {
      return '';
    }
    var str = '';
    if (value is Iterable) {
      str = value.join(',');
    } else {
      str = value.toString();
    }
    return str != '' ? '  $name: $str,\n' : '';
  }

  /// Regex to check if a host name is an IP address
  static RegExp regIP = RegExp(
      r'(\\[[0-9a-f:]+\\]|[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3})',
      caseSensitive: false);

  /// Host lookup, does not use the resolver if the host is an IP address.
  static Future<CoapInternetAddress?> lookupHost(String host,
      InternetAddressType addressType, InternetAddress? bindAddress) async {
    final parsedAddress = InternetAddress.tryParse(host);
    if (parsedAddress != null) {
      return CoapInternetAddress(
          parsedAddress.type, parsedAddress, bindAddress);
    }

    final addresses = await InternetAddress.lookup(host, type: addressType);
    if (addresses.isNotEmpty) {
      return CoapInternetAddress(addressType, addresses[0], bindAddress);
    }
    return null;
  }
}
