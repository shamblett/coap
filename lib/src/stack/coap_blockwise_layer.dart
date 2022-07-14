/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/05/2018
 * Copyright :  S.Hamblett
 */

import 'dart:async';
import 'dart:math';

import 'package:typed_data/typed_data.dart';

import '../coap_block_option.dart';
import '../coap_code.dart';
import '../coap_config.dart';
import '../coap_empty_message.dart';
import '../coap_message.dart';
import '../coap_message_type.dart';
import '../coap_option.dart';
import '../coap_option_type.dart';
import '../coap_request.dart';
import '../coap_response.dart';
import '../net/coap_exchange.dart';
import '../net/coap_multicast_exchange.dart';
import 'coap_abstract_layer.dart';
import 'coap_blockwise_status.dart';
import 'coap_ilayer.dart';

/// Blockwise layer
class CoapBlockwiseLayer extends CoapAbstractLayer {
  /// Constructs a blockwise layer.
  CoapBlockwiseLayer(final DefaultCoapConfig config) {
    _maxMessageSize = config.maxMessageSize;
    _preferredBlockSize = config.preferredBlockSize;
    _blockTimeout = config.blockwiseStatusLifetime;
  }

  late int _maxMessageSize;
  late int _preferredBlockSize;
  late int _blockTimeout;

  @override
  void sendRequest(
    final CoapINextLayer nextLayer,
    final CoapExchange initialExchange,
    final CoapRequest request,
  ) {
    final exchange = initialExchange;

    if (request.hasOption(OptionType.block2) && request.block2!.num > 0) {
      // This is the case if the user has explicitly added a block option
      // for random access.
      // Note: We do not regard it as random access when the block num is
      // 0. This is because the user might just want to do early block
      // size negotiation but actually wants to receive all blocks.
      final status = CoapBlockwiseStatus(request.contentFormat)
        ..currentSZX = request.block2!.szx
        ..currentNUM = request.block2!.num
        ..randomAccess = true;
      exchange.responseBlockStatus = status;
      super.sendRequest(nextLayer, exchange, request);
    } else if (_requiresBlockwise(request)) {
      // This must be a large POST or PUT request
      final status = _findRequestBlockStatus(exchange, request);
      final block = _getNextRequestBlock(request, status);
      exchange
        ..requestBlockStatus = status
        ..currentRequest = block;
      super.sendRequest(nextLayer, exchange, block);
    } else {
      exchange.currentRequest = request;
      super.sendRequest(nextLayer, exchange, request);
    }
  }

  @override
  void receiveRequest(
    final CoapINextLayer nextLayer,
    final CoapExchange initialExchange,
    final CoapRequest request,
  ) {
    final exchange = initialExchange;

    if (request.hasOption(OptionType.block1)) {
      // This must be a large POST or PUT request
      final block1 = request.block1!;

      var status = _findRequestBlockStatus(exchange, request);
      if (block1.num == 0 && status.currentNUM > 0) {
        // Reset the blockwise transfer
        status = CoapBlockwiseStatus(request.contentType);
        exchange.requestBlockStatus = status;
      }

      if (block1.num == status.currentNUM) {
        if (request.contentType == status.contentFormat) {
          status.addBlock(request.payload);
        } else {
          final error = CoapResponse.createResponse(
            request,
            CoapCode.requestEntityIncomplete,
          )
            ..addOption(
              CoapBlockOption.fromParts(
                OptionType.block1,
                block1.num,
                block1.szx,
                m: block1.m,
              ),
            )
            ..setPayload('Changed Content-Format');

          exchange.currentResponse = error;
          super.sendResponse(nextLayer, exchange, error);
          return;
        }

        status.currentNUM++;
        if (block1.m) {
          final piggybacked =
              CoapResponse.createResponse(request, CoapCode.continues)
                ..addOption(
                  CoapBlockOption.fromParts(
                    OptionType.block1,
                    block1.num,
                    block1.szx,
                    m: true,
                  ),
                )
                ..last = false;

          exchange.currentResponse = piggybacked;
          super.sendResponse(nextLayer, exchange, piggybacked);

          // Do not assemble and deliver the request yet
        } else {
          // Remember block to acknowledge.
          exchange.block1ToAck = block1;

          // Block2 early negotiation
          _earlyBlock2Negotiation(exchange, request);

          // Assemble and deliver
          final assembled = CoapRequest(request.method);
          _assembleMessage(status, assembled, request);

          exchange.request = assembled;
          super.receiveRequest(nextLayer, exchange, assembled);
        }
      } else {
        // ERROR, wrong number, Incomplete
        final error = CoapResponse.createResponse(
          request,
          CoapCode.requestEntityIncomplete,
        )
          ..addOption(
            CoapBlockOption.fromParts(
              OptionType.block1,
              block1.num,
              block1.szx,
              m: block1.m,
            ),
          )
          ..setPayload('Wrong block number');
        exchange.currentResponse = error;
        super.sendResponse(nextLayer, exchange, error);
      }
    } else if (exchange.response != null &&
        request.hasOption(OptionType.block2)) {
      // The response has already been generated and the client just wants
      // the next block of it
      final block2 = request.block2!;
      final response = exchange.response!;
      final status = _findResponseBlockStatus(exchange, response)
        ..currentNUM = block2.num
        ..currentSZX = block2.szx;

      final block = _getNextResponseBlock(response, status)
        ..token = request.token
        ..removeOptions(OptionType.observe);

      if (status.complete) {
        // Clean up blockwise status
        exchange.responseBlockStatus = null;
        _clearBlockCleanup(exchange);
      }

      exchange.currentResponse = block;
      super.sendResponse(nextLayer, exchange, block);
    } else {
      _earlyBlock2Negotiation(exchange, request);

      exchange.request = request;
      super.receiveRequest(nextLayer, exchange, request);
    }
  }

  @override
  void sendResponse(
    final CoapINextLayer nextLayer,
    final CoapExchange initialExchange,
    final CoapResponse? response,
  ) {
    final exchange = initialExchange;

    final block1 = exchange.block1ToAck;
    if (block1 != null) {
      exchange.block1ToAck = null;
    }

    if (_requiresBlockwiseExchange(exchange, response!)) {
      final status = _findResponseBlockStatus(exchange, response);

      final block = _getNextResponseBlock(response, status);

      if (block1 != null) {
        // In case we still have to ack the last block1
        block.setOption(block1);
      }
      block.token ??= exchange.request!.token;

      if (status.complete) {
        // Clean up blockwise status
        exchange.responseBlockStatus = null;
        _clearBlockCleanup(exchange);
      }

      exchange.currentResponse = block;
      super.sendResponse(nextLayer, exchange, block);
    } else {
      if (block1 != null) {
        response.setOption(block1);
      }
      exchange.currentResponse = response;
      // Block1 transfer completed
      _clearBlockCleanup(exchange);
      super.sendResponse(nextLayer, exchange, response);
    }
  }

  CoapBlockwiseStatus _copyBlockStatus(
    final CoapBlockwiseStatus? oldBlockwiseStatus,
    final int currentSZX,
  ) {
    final newStatus = CoapBlockwiseStatus.withSize(
      oldBlockwiseStatus!.contentFormat,
      oldBlockwiseStatus.currentNUM,
      currentSZX,
    )..blocks = oldBlockwiseStatus.blocks;
    return newStatus;
  }

  CoapExchange _convertMutlicastToUnicastExchange(
    final CoapMulticastExchange exchange,
    final CoapRequest block,
  ) {
    final endpoint = exchange.endpoint;
    final originalRequest = exchange.request;
    final newExchange =
        CoapExchange(block, exchange.origin, namespace: exchange.namespace)
          ..originalMulticastRequest = originalRequest
          ..endpoint = endpoint;
    block.type = CoapMessageType.con;
    return newExchange;
  }

  @override
  void receiveResponse(
    final CoapINextLayer nextLayer,
    final CoapExchange initialExchange,
    final CoapResponse response,
  ) {
    var exchange = initialExchange;

    // Do not continue fetching blocks if canceled
    if (exchange.request!.isCancelled) {
      // Reject (in particular for Block+Observe)
      if (response.type != CoapMessageType.ack) {
        final rst = CoapEmptyMessage.newRST(response);
        sendEmptyMessage(nextLayer, exchange, rst);
        // Matcher sets exchange as complete when RST is sent
      }
      return;
    }

    if (!response.hasOption(OptionType.block1) &&
        !response.hasOption(OptionType.block2)) {
      // There is no block1 or block2 option, therefore it is a normal response
      exchange.response = response;
      super.receiveResponse(nextLayer, exchange, response);
      return;
    }

    final block1 = response.block1;
    if (block1 != null) {
      final status = exchange.requestBlockStatus!;
      if (!status.complete) {
        // Send next block
        final currentSize = 1 << (4 + status.currentSZX);
        final nextNum =
            (status.currentNUM + currentSize / block1.size()).toInt();
        status
          ..currentNUM = nextNum
          ..currentSZX = block1.szx;
        final nextBlock = _getNextRequestBlock(exchange.request!, status);
        if (exchange is CoapMulticastExchange) {
          exchange = _convertMutlicastToUnicastExchange(exchange, nextBlock);
        } else {
          nextBlock.token ??= response.token; // reuse same token
        }
        exchange.currentRequest = nextBlock;
        super.sendRequest(nextLayer, exchange, nextBlock);
        // Do not deliver response
      } else if (!response.hasOption(OptionType.block2)) {
        // All request block have been acknowledged and we
        // receive a piggy-backed response that needs no blockwise
        // transfer. Thus, deliver it.
        _clearBlockCleanup(exchange);
        super.receiveResponse(nextLayer, exchange, response);
      }
    }

    final block2 = response.block2;
    if (block2 != null) {
      var status = _findResponseBlockStatus(exchange, response);
      final blockStatus = CoapBlockOption(OptionType.block2)
        ..rawValue = status.currentNUM;
      if (block2.num == blockStatus.num) {
        // We got the block we expected
        status.addBlock(response.payload);
        final obs = response.observe;
        if (obs != null) {
          status.observe = obs;
        }

        // Notify blocking progress
        exchange.fireResponding(response);

        if (status.isRandomAccess) {
          // The client has requested this specific block and we deliver it
          exchange.response = response;
          _clearBlockCleanup(exchange);
          super.receiveResponse(nextLayer, exchange, response);
        } else if (block2.m) {
          final request = exchange.request!;
          final num = block2.num + 1;
          final szx = block2.szx;
          final m = block2.m;

          final nextBlock =
              CoapBlockOption.fromParts(OptionType.block2, num, szx, m: m);
          final block = CoapRequest(request.method)
            ..endpoint = request.endpoint
            // NON could make sense over SMS or similar transports
            ..type = request.type
            ..setOptions(request.getAllOptions())
            ..setOption(nextBlock)
            ..destination = response.source
            ..uriHost = response.source?.host;
          if (exchange is CoapMulticastExchange) {
            status = _copyBlockStatus(
              exchange.responseBlockStatus,
              nextBlock.intValue,
            );
            exchange = _convertMutlicastToUnicastExchange(exchange, block);
          } else {
            // We use the same token to ease traceability
            // (GET without Observe no longer cancels relations)
            block.token = response.token;
          }

          // Make sure not to use Observe for block retrieval
          block.removeOptions(OptionType.observe);
          status.currentNUM = nextBlock.intValue;
          exchange
            ..currentRequest = block
            ..responseBlockStatus = status;
          super.sendRequest(nextLayer, exchange, block);
        } else {
          final assembled = CoapResponse(response.statusCode);
          _assembleMessage(status, assembled, response);

          assembled
            ..type = response.type
            // Set overall transfer RTT
            ..rtt = DateTime.now().difference(exchange.timestamp!);

          // Check if this response is a notification
          final observe = status.observe;
          if (observe != CoapBlockwiseStatus.noObserve) {
            assembled
                .addOption(CoapOption.createVal(OptionType.observe, observe));
            // This is necessary for notifications that are sent blockwise:
            // Reset block number AND container with all blocks
            exchange.responseBlockStatus = null;
          }

          exchange.response = assembled;
          _clearBlockCleanup(exchange);
          super.receiveResponse(nextLayer, exchange, assembled);
        }
      } else {
        // ERROR, wrong block number (server error)
        // Currently, we reject it and cancel the request.
        if (response.type == CoapMessageType.con) {
          final rst = CoapEmptyMessage.newRST(response);
          super.sendEmptyMessage(nextLayer, exchange, rst);
        }
        exchange.request!.isCancelled = true;
      }
    }
  }

  bool _requiresBlockwise(final CoapRequest request) {
    if (request.method == CoapCode.methodPUT ||
        request.method == CoapCode.methodPOST) {
      return request.payloadSize > _maxMessageSize;
    }
    return false;
  }

  CoapBlockwiseStatus _findRequestBlockStatus(
    final CoapExchange exchange,
    final CoapRequest request,
  ) {
    var status = exchange.requestBlockStatus;
    if (status == null) {
      status = CoapBlockwiseStatus(request.contentType)
        ..currentSZX = CoapBlockOption.encodeSZX(_preferredBlockSize);
      exchange.requestBlockStatus = status;
    }
    // sets a timeout to complete exchange
    _prepareBlockCleanup(exchange);
    return status;
  }

  CoapRequest _getNextRequestBlock(
    final CoapRequest request,
    final CoapBlockwiseStatus status,
  ) {
    final num = status.currentNUM;
    final szx = status.currentSZX;
    final block = CoapRequest(request.method)
      ..endpoint = request.endpoint
      ..setOptions(request.getAllOptions())
      ..destination = request.destination
      ..token = request.token
      ..type = CoapMessageType.con;

    final currentSize = 1 << (4 + szx);
    final from = num * currentSize;
    final to = min((num + 1) * currentSize, request.payloadSize);
    final length = to - from;
    block.payload = Uint8Buffer()
      ..addAll(request.payload!.getRange(from, from + length));

    final m = to < request.payloadSize;
    block.addOption(
      CoapBlockOption.fromParts(OptionType.block1, num, szx, m: m),
    );

    status.complete = !m;
    return block;
  }

  void _earlyBlock2Negotiation(
    final CoapExchange exchange,
    final CoapRequest request,
  ) {
    // Call this method when a request has completely arrived (might have
    // been sent in one piece without blockwise).
    if (request.hasOption(OptionType.block2)) {
      final block2 = request.block2!;
      final status2 = CoapBlockwiseStatus.withSize(
        request.contentType,
        block2.num,
        block2.szx,
      );
      exchange.responseBlockStatus = status2;
    }
  }

  void _assembleMessage(
    final CoapBlockwiseStatus status,
    final CoapMessage message,
    final CoapMessage last,
  ) {
    // The assembled request will contain the options of the last block
    message
      ..id = last.id
      ..source = last.source
      ..token = last.token
      ..type = last.type
      ..setOptions(last.getAllOptions());

    final payload = Uint8Buffer();
    status.blocks.forEach(payload.addAll);
    message.payload = payload;
  }

  CoapBlockwiseStatus _findResponseBlockStatus(
    final CoapExchange exchange,
    final CoapResponse? response,
  ) {
    var status = exchange.responseBlockStatus;
    if (status == null || exchange is CoapMulticastExchange) {
      final blockOptions = response!.getOptions(OptionType.block2)!;
      status = CoapBlockwiseStatus(response.contentType)
        ..currentSZX = CoapBlockOption.encodeSZX(_preferredBlockSize)
        ..currentNUM = blockOptions.toList()[0].value as int
        ..complete = false;
      exchange.responseBlockStatus = status;
    }

    // Sets a timeout to complete exchange
    _prepareBlockCleanup(exchange);
    return status;
  }

  CoapResponse _getNextResponseBlock(
    final CoapResponse response,
    final CoapBlockwiseStatus status,
  ) {
    CoapResponse block;
    final szx = status.currentSZX;
    final num = status.currentNUM;

    if (response.hasOption(OptionType.observe)) {
      // A blockwise notification transmits the first block only
      block = response;
    } else {
      block = CoapResponse(response.statusCode)
        ..destination = response.destination
        ..token = response.token
        ..setOptions(response.getAllOptions())
        ..isTimedOut = true;
    }

    final payloadSize = response.payloadSize;
    final currentSize = 1 << (4 + szx);
    final from = num * currentSize;
    if (payloadSize > 0 && payloadSize > from) {
      final to = min((num + 1) * currentSize, response.payloadSize);
      final length = to - from;
      final blockPayload = Uint8Buffer();
      final m = to < response.payloadSize;
      block.setBlock2(szx, num, m: m);

      // Crop payload -- do after calculation of m in case block==response
      blockPayload.addAll(response.payload!.getRange(from, from + length));

      block
        ..payload = blockPayload
        // Do not complete notifications
        ..last = !m && !response.hasOption(OptionType.observe);

      status.complete = !m;
    } else {
      block
        ..addOption(
          CoapBlockOption.fromParts(OptionType.block2, num, szx),
        )
        ..last = true;
      status.complete = true;
    }

    return block;
  }

  /// Schedules a clean-up task.
  void _prepareBlockCleanup(final CoapExchange exchange) {
    final timer = Timer(
      Duration(milliseconds: _blockTimeout),
      () => _blockwiseTimeout(exchange),
    );
    final old = exchange.set<Timer>('BlockCleanupTimer', timer);
    old?.cancel();
  }

  /// Clears the clean-up task.
  void _clearBlockCleanup(final CoapExchange exchange) {
    final timer = exchange.remove('BlockCleanupTimer') as Timer?;
    timer?.cancel();
  }

  void _blockwiseTimeout(final CoapExchange exchange) {
    exchange.complete = true;
  }

  bool _requiresBlockwiseExchange(
    final CoapExchange exchange,
    final CoapResponse response,
  ) =>
      response.payloadSize > _maxMessageSize ||
      exchange.responseBlockStatus != null;
}
