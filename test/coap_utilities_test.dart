/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 13/04/2017
 * Copyright :  S.Hamblett
 */
import 'dart:io';

import 'package:coap/coap.dart';
import 'package:coap/config/coap_config_all.dart';
import 'package:coap/config/coap_config_default.dart';
import 'package:coap/config/coap_config_logging.dart';
import 'package:test/test.dart';

void main() {
  group('Hostname and IP', () {
    test('Is an IP address', () {
      final hostname = 'coap.me';
      final ip4Address = '192.168.0.20';
      final ip6Address = 'fe80::3475:2418:e6b3:36c1';
      var res = CoapUtil.isAnIpAddress(hostname, InternetAddressType.IPv4);
      expect(res, isFalse);
      res = CoapUtil.isAnIpAddress(ip4Address, InternetAddressType.IPv4);
      expect(res, isTrue);
      res = CoapUtil.isAnIpAddress(ip6Address, InternetAddressType.IPv6);
      expect(res, isTrue);
    });
  });
}
