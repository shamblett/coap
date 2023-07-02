/*
 * Package : Coap
 * Author : J. Romann <jan.romann@uni-bremen.de>
 * Date   : 10/15/2022
 * Copyright :  J. Romann
 *
 * CoAP Server implementation
 */

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:typed_data/typed_data.dart';

import '../config/coap_config_default.dart';
import 'coap_code.dart';
import 'coap_config.dart';
import 'coap_empty_message.dart';
import 'coap_media_type.dart';
import 'coap_message.dart';
import 'coap_message_type.dart';
import 'coap_request.dart';
import 'coap_response.dart';
import 'stack/layer_stack.dart';

enum CoapUriScheme {
  coap,
  coaps,
  coapWs,
  coapsWs,
  coapTcp,
  coapsTcp,
}

abstract class CoapServer extends Stream<CoapRequest> {
  CoapServer();

  static Future<CoapServer> bind(
    final Object? host,
    final CoapUriScheme uriScheme, {
    final DefaultCoapConfig? config,
    final bool reuseAddress = true,
    final bool reusePort = false,
  }) async {
    switch (uriScheme) {
      case CoapUriScheme.coap:
        return _createUdpServer(
          host,
          config: config,
          reuseAddress: reuseAddress,
          reusePort: reusePort,
        );
      case CoapUriScheme.coaps:
      case CoapUriScheme.coapWs:
      case CoapUriScheme.coapsWs:
      case CoapUriScheme.coapTcp:
      case CoapUriScheme.coapsTcp:
        throw UnimplementedError();
    }
  }

  static Future<CoapServer> _createUdpServer(
    final Object? host, {
    final DefaultCoapConfig? config,
    final bool reuseAddress = true,
    final bool reusePort = false,
  }) async {
    final serverConfig = config ?? CoapConfigDefault();
    final coapPort = serverConfig.defaultPort;

    final socket = await RawDatagramSocket.bind(
      host,
      coapPort,
      reuseAddress: reuseAddress,
      reusePort: reusePort,
    );

    return _CoapUdpServer(socket, coapPort, serverConfig);
  }

  int get port;

  String get uriScheme;

  void sendResponse(
    final CoapResponse response,
    final InternetAddress address,
    final int port,
  );

  void respond(
    final CoapRequest request, {
    required final ResponseCode responseCode,
    final Uint8List? payload,
    final CoapMediaType? contentFormat,
  });

  void reject(final CoapRequest request);

  void close();
}

class _CoapUdpServer extends CoapServer {
  // ignore: unused_field
  final DefaultCoapConfig _config;

  final streamController = StreamController<CoapRequest>();

  final stack = LayerStack(CoapConfigDefault());

  @override
  void close() {
    streamController.close();
    _socket.close();
  }

  _CoapUdpServer(this._socket, this.port, this._config) {
    _socket.listen((final event) {
      if (event != RawSocketEvent.read) {
        return;
      }

      final datagram = _socket.receive();
      if (datagram == null) {
        return;
      }
      final data = Uint8Buffer()..addAll(datagram.data);
      final message = CoapMessage.fromUdpPayload(data, uriScheme);
      if (message is CoapRequest && !message.hasFormatError) {
        if (message.hasUnknownCriticalOption) {
          _rejectRequest(message, datagram.address, datagram.port);
          return;
        }
        message
          ..source = datagram.address
          ..sourcePort = datagram.port;
        streamController.sink.add(message);
      }
    });
  }

  @override
  final uriScheme = 'coap';

  @override
  final int port;

  final RawDatagramSocket _socket;

  @override
  StreamSubscription<CoapRequest> listen(
    final void Function(CoapRequest event)? onData, {
    final Function? onError,
    final void Function()? onDone,
    final bool? cancelOnError,
  }) =>
      streamController.stream.listen(
        onData,
        onError: onError,
        onDone: () {
          onDone?.call();
        },
        cancelOnError: cancelOnError,
      );

  @override
  void sendResponse(
    final CoapResponse response,
    final InternetAddress address,
    final int port,
  ) {
    _send(response, address, port);
  }

  void _rejectRequest(
    final CoapRequest request,
    final InternetAddress address,
    final int port,
  ) {
    final resetMessage = CoapEmptyMessage.newRST(request);
    _send(resetMessage, address, port);
  }

  void _send(
    final CoapMessage message,
    final InternetAddress address,
    final int port,
  ) {
    _socket.send(message.toUdpPayload().toList(), address, port);
  }

  @override
  void respond(
    final CoapRequest request, {
    required final ResponseCode responseCode,
    final Uint8List? payload,
    final CoapMediaType? contentFormat,
  }) {
    final response = CoapResponse.createResponse(
      request,
      ResponseCode.content,
      CoapMessageType.ack,
      payload: payload,
    )
      ..id = request.id
      ..contentFormat = contentFormat;

    _send(response, request.source!, request.sourcePort!);
  }

  @override
  void reject(final CoapRequest request) {
    _rejectRequest(request, request.source!, request.sourcePort!);
  }
}
