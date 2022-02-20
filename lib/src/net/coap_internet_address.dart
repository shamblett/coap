/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 05/09/2019
 * Copyright :  S.Hamblett
 */

part of coap;

/// Internet address
class CoapInternetAddress {
  /// Construction
  CoapInternetAddress(this.type, this.address, [this.bindAddress]);

  /// IPV4 default bind address
  static const String ipv4DefaultBind = '0.0.0.0';

  /// IPV6 default bind address
  static const String ipv6DefaultBind = '0:0:0:0:0:0:0:0';

  /// Type
  InternetAddressType type;

  /// Address
  InternetAddress address;

  /// Bind address if not using the default of all interfaces, note this
  /// address type must match the type selection
  InternetAddress? bindAddress;

  /// The bind address
  String get bind {
    if (bindAddress != null) {
      return bindAddress.toString();
    }
    if (type == InternetAddressType.IPv4) {
      return ipv4DefaultBind;
    } else {
      return ipv6DefaultBind;
    }
  }

  /// Equality, deemed to be equal if the address and bind address are the same
  @override
  bool operator ==(dynamic other) {
    if (other is CoapInternetAddress) {
      if (other.address == address && other.bindAddress == bindAddress) {
        return true;
      }
    }
    return false;
  }
}
