/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

/// Blockwise layer
class CoapBlockwiseLayer extends CoapAbstractLayer {
  /// Constructs a blockwise layer.
  CoapBlockwiseLayer(DefaultCoapConfig config) {
    _maxMessageSize = config.maxMessageSize;
    _defaultBlockSize = config.defaultBlockSize;
    _blockTimeout = config.blockwiseStatusLifetime;
    _log.debug('BlockwiseLayer uses MaxMessageSize: $_maxMessageSize '
        'and DefaultBlockSize: $_defaultBlockSize');
  }

  final CoapILogger _log = CoapLogManager().logger;

  int _maxMessageSize;
  int _defaultBlockSize;
  int _blockTimeout;

  @override
  void sendRequest(
      CoapINextLayer nextLayer, CoapExchange exchange, CoapRequest request) {
    if (request.hasOption(optionTypeBlock2) && request.block2.num > 0) {
      // This is the case if the user has explicitly added a block option
      // for random access.
      // Note: We do not regard it as random access when the block num is
      // 0. This is because the user might just want to do early block
      // size negotiation but actually wants to receive all blocks.
      _log.info('Request carries explicit defined block2 option: create random '
          'access blockwise status');
      final status = CoapBlockwiseStatus(request.contentFormat);
      final block2 = request.block2;
      status.currentSZX = block2.szx;
      status.currentNUM = block2.num;
      status.randomAccess = true;
      exchange.responseBlockStatus = status;
      super.sendRequest(nextLayer, exchange, request);
    } else if (_requiresBlockwise(request)) {
      // This must be a large POST or PUT request
      _log.info(
          'Request payload ${request.payloadSize} / $_maxMessageSize requires Blockwise.');
      final status = _findRequestBlockStatus(exchange, request);
      final block = _getNextRequestBlock(request, status);
      exchange.requestBlockStatus = status;
      exchange.currentRequest = block;
      super.sendRequest(nextLayer, exchange, block);
    } else {
      exchange.currentRequest = request;
      super.sendRequest(nextLayer, exchange, request);
    }
  }

  @override
  void receiveRequest(
      CoapINextLayer nextLayer, CoapExchange exchange, CoapRequest request) {
    if (request.hasOption(optionTypeBlock1)) {
      // This must be a large POST or PUT request
      final block1 = request.block1;
      _log.info('Request contains block1 option $block1');

      var status = _findRequestBlockStatus(exchange, request);
      if (block1.num == 0 && status.currentNUM > 0) {
        // Reset the blockwise transfer
        _log.info('Block1 num is 0, the client has restarted the blockwise '
            'transfer. Reset status.');
        status = CoapBlockwiseStatus(request.contentType);
        exchange.requestBlockStatus = status;
      }

      if (block1.num == status.currentNUM) {
        if (request.contentType == status.contentFormat) {
          status.addBlock(request.payload);
        } else {
          final error = CoapResponse.createResponse(
              request, CoapCode.requestEntityIncomplete);
          error.addOption(CoapBlockOption.fromParts(
              optionTypeBlock1, block1.num, block1.szx,
              m: block1.m));
          error.setPayload('Changed Content-Format');

          exchange.currentResponse = error;
          super.sendResponse(nextLayer, exchange, error);
          return;
        }

        status.currentNUM = status.currentNUM + 1;
        if (block1.m) {
          _log.info('There are more blocks to come. Acknowledge this block.');

          final piggybacked =
              CoapResponse.createResponse(request, CoapCode.continues);
          piggybacked.addOption(CoapBlockOption.fromParts(
              optionTypeBlock1, block1.num, block1.szx,
              m: true));
          piggybacked.last = false;

          exchange.currentResponse = piggybacked;
          super.sendResponse(nextLayer, exchange, piggybacked);

          // Do not assemble and deliver the request yet
        } else {
          _log.info('This was the last block. Deliver request');

          // Remember block to acknowledge.
          exchange.block1ToAck = block1;

          // Block2 early negotiation
          _earlyBlock2Negotiation(exchange, request);

          // Assemble and deliver
          final assembled = CoapRequest.withType(request.method);
          _assembleMessage(status, assembled, request);

          exchange.request = assembled;
          super.receiveRequest(nextLayer, exchange, assembled);
        }
      } else {
        // ERROR, wrong number, Incomplete
        _log.warn('Wrong block number. Expected ${status.currentNUM} '
            'but received ${block1.num} '
            'Respond with 4.08 (Request Entity Incomplete).');
        final error = CoapResponse.createResponse(
            request, CoapCode.requestEntityIncomplete);
        error.addOption(CoapBlockOption.fromParts(
            optionTypeBlock1, block1.num, block1.szx,
            m: block1.m));
        error.setPayload('Wrong block number');
        exchange.currentResponse = error;
        super.sendResponse(nextLayer, exchange, error);
      }
    } else if (exchange.response != null &&
        request.hasOption(optionTypeBlock2)) {
      // The response has already been generated and the client just wants
      // the next block of it
      final block2 = request.block2;
      final response = exchange.response;
      final status = _findResponseBlockStatus(exchange, response);
      status.currentNUM = block2.num;
      status.currentSZX = block2.szx;

      final block = _getNextResponseBlock(response, status);
      block.token = request.token;
      block.removeOptions(optionTypeObserve);

      if (status.complete) {
        // Clean up blockwise status
        _log.info('Ongoing is complete $status');
        exchange.responseBlockStatus = null;
        _clearBlockCleanup(exchange);
      } else {
        _log.info('Ongoing is continuing $status');
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
      CoapINextLayer nextLayer, CoapExchange exchange, CoapResponse response) {
    final block1 = exchange.block1ToAck;
    if (block1 != null) {
      exchange.block1ToAck = null;
    }

    if (_requiresBlockwiseExchange(exchange, response)) {
      _log.info(
          'Response payload ${response.payloadSize} / $_maxMessageSize requires Blockwise');

      final status = _findResponseBlockStatus(exchange, response);

      final block = _getNextResponseBlock(response, status);

      if (block1 != null) {
        // In case we still have to ack the last block1
        block.setOption(block1);
      }
      block.token ??= exchange.request.token;

      if (status.complete) {
        // Clean up blockwise status
        _log.info('Ongoing finished on first block $status');
        exchange.responseBlockStatus = null;
        _clearBlockCleanup(exchange);
      } else {
        _log.info('Ongoing started $status');
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

  @override
  void receiveResponse(
      CoapINextLayer nextLayer, CoapExchange exchange, CoapResponse response) {
    // Do not continue fetching blocks if canceled
    if (exchange.request.isCancelled) {
      // Reject (in particular for Block+Observe)
      if (response.type != CoapMessageType.ack) {
        _log.warn('Rejecting blockwise transfer for canceled Exchange');
        final rst = CoapEmptyMessage.newRST(response);
        sendEmptyMessage(nextLayer, exchange, rst);
        // Matcher sets exchange as complete when RST is sent
      }
      return;
    }

    if (!response.hasOption(optionTypeBlock1) &&
        !response.hasOption(optionTypeBlock2)) {
      // There is no block1 or block2 option, therefore it is a normal response
      exchange.response = response;
      super.receiveResponse(nextLayer, exchange, response);
      return;
    }

    final block1 = response.block1;
    if (block1 != null) {
      _log.info('Blockwise block1 - response acknowledges block $block1');
      final status = exchange.requestBlockStatus;
      _log.info('Blockwise exchange block1 status is - $status');
      if (!status.complete) {
        // Send next block
        final currentSize = 1 << (4 + status.currentSZX);
        final nextNum =
            (status.currentNUM + currentSize / block1.size()).toInt();
        _log.info('Send next block num = $nextNum');
        status.currentNUM = nextNum;
        status.currentSZX = block1.szx;
        final nextBlock = _getNextRequestBlock(exchange.request, status);
        nextBlock.token ??= response.token; // reuse same token
        exchange.currentRequest = nextBlock;
        super.sendRequest(nextLayer, exchange, nextBlock);
        // Do not deliver response
      } else if (!response.hasOption(optionTypeBlock2)) {
        // All request block have been acknowledged and we
        // receive a piggy-backed response that needs no blockwise
        // transfer. Thus, deliver it.
        super.receiveResponse(nextLayer, exchange, response);
      } else {
        _log.info('Response has Block2 option and is therefore sent blockwise');
      }
    }

    final block2 = response.block2;
    if (block2 != null) {
      _log.info('Blockwise block2 - response acknowledges block: $block2');
      final status = _findResponseBlockStatus(exchange, response);
      _log.info('Blockwise exchange block2 status is - $status');
      final blockStatus = CoapBlockOption(optionTypeBlock2);
      blockStatus.rawValue = status.currentNUM;
      if (status != null && block2.num == blockStatus.num) {
        // We got the block we expected
        _log.info('Blockwise - Received expected block');
        status.addBlock(response.payload);
        final obs = response.observe;
        if (obs != null) {
          status.observe = obs;
        }

        // Notify blocking progress
        exchange.request.fireResponding(response);

        if (status.isRandomAccess) {
          // The client has requested this specific block and we deliver it
          exchange.response = response;
          super.receiveResponse(nextLayer, exchange, response);
        } else if (block2.m) {
          _log.info('Blockwise - Request the next response block');

          final request = exchange.request;
          final num = block2.num + 1;
          final szx = block2.szx;
          final m = block2.m;

          final block = CoapRequest.withType(request.method);
          // NON could make sense over SMS or similar transports
          block.type = request.type;
          block.destination = request.destination;
          block.setOptions(request.getAllOptions());
          final nextBlock =
              CoapBlockOption.fromParts(optionTypeBlock2, num, szx, m: m);
          block.setOption(nextBlock);
          // We use the same token to ease traceability
          // (GET without Observe no longer cancels relations)
          block.token = response.token;
          // Make sure not to use Observe for block retrieval
          block.removeOptions(optionTypeObserve);
          status.currentNUM = nextBlock.intValue;
          exchange.currentRequest = block;
          exchange.responseBlockStatus = status;
          _log.info('Blockwise - requesting next response - '
              'block number $num, szx: $szx');
          super.sendRequest(nextLayer, exchange, block);
        } else {
          _log.info('Blockwise - We have received all ${status.blockCount} '
              'blocks of the response. Assemble and deliver.');
          final assembled = CoapResponse(response.statusCode);
          _assembleMessage(status, assembled, response);
          assembled.type = response.type;

          // Set overall transfer RTT
          assembled.rtt = (DateTime.now().difference(exchange.timestamp))
              .inMilliseconds
              .toDouble();

          // Check if this response is a notification
          final observe = status.observe;
          if (observe != CoapBlockwiseStatus.noObserve) {
            assembled
                .addOption(CoapOption.createVal(optionTypeObserve, observe));
            // This is necessary for notifications that are sent blockwise:
            // Reset block number AND container with all blocks
            exchange.responseBlockStatus = null;
          }

          _log.info('Assembled response: $assembled');
          exchange.response = assembled;
          super.receiveResponse(nextLayer, exchange, assembled);
        }
      } else {
        // ERROR, wrong block number (server error)
        // Currently, we reject it and cancel the request.
        _log.warn('Wrong block number. Expected ${status?.currentNUM} '
            'but received ${block2.num}. Reject response; '
            'exchange has failed.');
        if (response.type == CoapMessageType.con) {
          final rst = CoapEmptyMessage.newRST(response);
          super.sendEmptyMessage(nextLayer, exchange, rst);
        }
        exchange.request.isCancelled = true;
      }
    }
  }

  bool _requiresBlockwise(CoapRequest request) {
    if (request.method == CoapCode.methodPUT ||
        request.method == CoapCode.methodPOST) {
      return request.payloadSize > _maxMessageSize;
    } else {
      return false;
    }
  }

  CoapBlockwiseStatus _findRequestBlockStatus(
      CoapExchange exchange, CoapRequest request) {
    var status = exchange.requestBlockStatus;
    if (status == null) {
      status = CoapBlockwiseStatus(request.contentType);
      status.currentSZX = CoapBlockOption.encodeSZX(_defaultBlockSize);
      exchange.requestBlockStatus = status;
      _log.info('There is no assembler status yet. '
          'Create and set Block1 status: $status');
    } else {
      _log.info('Current Block1 status: $status');
    }
    // sets a timeout to complete exchange
    _prepareBlockCleanup(exchange);
    return status;
  }

  CoapRequest _getNextRequestBlock(
      CoapRequest request, CoapBlockwiseStatus status) {
    final num = status.currentNUM;
    final szx = status.currentSZX;
    final block = CoapRequest.withType(request.method);
    block.setOptions(request.getAllOptions());
    block.destination = request.destination;
    block.token = request.token;
    block.type = CoapMessageType.con;

    final currentSize = 1 << (4 + szx);
    final from = num * currentSize;
    final to = min((num + 1) * currentSize, request.payloadSize);
    final length = to - from;
    final blockPayload = typed.Uint8Buffer()
      ..addAll(request.payload.getRange(from, from + length));
    block.payload = blockPayload;

    final m = to < request.payloadSize;
    block
        .addOption(CoapBlockOption.fromParts(optionTypeBlock1, num, szx, m: m));

    status.complete = !m;
    return block;
  }

  void _earlyBlock2Negotiation(CoapExchange exchange, CoapRequest request) {
    // Call this method when a request has completely arrived (might have
    // been sent in one piece without blockwise).
    if (request.hasOption(optionTypeBlock2)) {
      final block2 = request.block2;
      final status2 = CoapBlockwiseStatus.withSize(
          request.contentType, block2.num, block2.szx);
      _log.info('Request with early block negotiation $block2. '
          'Create and set Block2 status: $status2');
      exchange.responseBlockStatus = status2;
    }
  }

  void _assembleMessage(
      CoapBlockwiseStatus status, CoapMessage message, CoapMessage last) {
    // The assembled request will contain the options of the last block
    message.id = last.id;
    message.source = last.source;
    message.token = last.token;
    message.type = last.type;
    message.setOptions(last.getAllOptions());

    final payload = typed.Uint8Buffer();
    status.blocks.forEach(payload.addAll);
    message.payload = payload;
  }

  CoapBlockwiseStatus _findResponseBlockStatus(
      CoapExchange exchange, CoapResponse response) {
    var status = exchange.responseBlockStatus;
    if (status == null) {
      status = CoapBlockwiseStatus(response.contentType);
      status.currentSZX = CoapBlockOption.encodeSZX(_defaultBlockSize);
      final blockOptions = response.getOptions(optionTypeBlock2);
      status.currentNUM = blockOptions.toList()[0].value;
      status.complete = false;
      exchange.responseBlockStatus = status;
      _log.info('There is no blockwise status yet. '
          'Create and set Block2 status: $status');
    } else {
      _log.info('Current Block2 status: $status');
    }

    // Sets a timeout to complete exchange
    _prepareBlockCleanup(exchange);
    return status;
  }

  CoapResponse _getNextResponseBlock(
      CoapResponse response, CoapBlockwiseStatus status) {
    CoapResponse block;
    final szx = status.currentSZX;
    final num = status.currentNUM;

    if (response.hasOption(optionTypeObserve)) {
      // A blockwise notification transmits the first block only
      block = response;
    } else {
      block = CoapResponse(response.statusCode);
      block.destination = response.destination;
      block.token = response.token;
      block.setOptions(response.getAllOptions());
      block.isTimedOut = true;
    }

    final payloadSize = response.payloadSize;
    final currentSize = 1 << (4 + szx);
    final from = num * currentSize;
    if (payloadSize > 0 && payloadSize > from) {
      final to = min((num + 1) * currentSize, response.payloadSize);
      final length = to - from;
      final blockPayload = typed.Uint8Buffer();
      final m = to < response.payloadSize;
      block.setBlock2(szx, num, m: m);

      // Crop payload -- do after calculation of m in case block==response
      blockPayload.addAll(response.payload.getRange(from, from + length));
      block.payload = blockPayload;

      // Do not complete notifications
      block.last = !m && !response.hasOption(optionTypeObserve);

      status.complete = !m;
    } else {
      block.addOption(
          CoapBlockOption.fromParts(optionTypeBlock2, num, szx, m: false));
      block.last = true;
      status.complete = true;
    }

    return block;
  }

  /// Schedules a clean-up task.
  void _prepareBlockCleanup(CoapExchange exchange) {
    final timer = Timer(Duration(milliseconds: _blockTimeout),
        () => _blockwiseTimeout(exchange));
    final old = exchange.set('BlockCleanupTimer', timer);
    old?.cancel();
  }

  /// Clears the clean-up task.
  void _clearBlockCleanup(CoapExchange exchange) {
    final Timer timer = exchange.remove('BlockCleanupTimer');
    timer?.cancel();
  }

  void _blockwiseTimeout(CoapExchange exchange) {
    if (exchange.request == null) {
      _log.warn('Block1 transfer timed out: $exchange.currentRequest');
    } else {
      _log.warn('Block2 transfer timed out: $exchange.request');
    }
    exchange.complete = true;
  }

  bool _requiresBlockwiseExchange(
          CoapExchange exchange, CoapResponse response) =>
      response.payloadSize > _maxMessageSize ||
      exchange.responseBlockStatus != null;
}
