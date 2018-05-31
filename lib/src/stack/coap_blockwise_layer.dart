/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 23/05/2018
 * Copyright :  S.Hamblett
 */

part of coap;

class CoapBlockwiseLayer extends CoapAbstractLayer {
  /// Constructs a new blockwise layer.
  CoapBlockwiseLayer(CoapConfig config) {
    _maxMessageSize = config.maxMessageSize;
    _defaultBlockSize = config.defaultBlockSize;
    _blockTimeout = config.blockwiseStatusLifetime;
    _log.debug(
        "BlockwiseLayer uses MaxMessageSize: $_maxMessageSize and DefaultBlockSize: $_defaultBlockSize");
  }

  static CoapILogger _log = new CoapLogManager("console").logger;

  int _maxMessageSize;
  int _defaultBlockSize;
  int _blockTimeout;

  @override
  void sendRequest(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapRequest request) {
    if (request.hasOption(optionTypeBlock2) && request.block2.num > 0) {
      // This is the case if the user has explicitly added a block option
      // for random access.
      // Note: We do not regard it as random access when the block num is
      // 0. This is because the user might just want to do early block
      // size negotiation but actually wants to receive all blocks.
      _log.debug(
          "Request carries explicit defined block2 option: create random access blockwise status");
      final CoapBlockwiseStatus status =
      new CoapBlockwiseStatus(request.contentFormat);
      final CoapBlockOption block2 = request.block2;
      status.currentSZX = block2.szx;
      status.currentNUM = block2.num;
      status.randomAccess = true;
      exchange.responseBlockStatus = status;
      super.sendRequest(nextLayer, exchange, request);
    } else if (_requiresBlockwise(request)) {
      // This must be a large POST or PUT request
      _log.debug(
          "Request payload ${request
              .payloadSize} / $_maxMessageSize requires Blockwise.");
      final CoapBlockwiseStatus status =
      _findRequestBlockStatus(exchange, request);
      final CoapRequest block = _getNextRequestBlock(request, status);
      exchange.requestBlockStatus = status;
      exchange.currentRequest = block;
      super.sendRequest(nextLayer, exchange, block);
    } else {
      exchange.currentRequest = request;
      super.sendRequest(nextLayer, exchange, request);
    }
  }

  @override
  void receiveRequest(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapRequest request) {
    if (request.hasOption(optionTypeBlock1)) {
      // This must be a large POST or PUT request
      final CoapBlockOption block1 = request.block1;
      _log.debug("Request contains block1 option $block1");

      CoapBlockwiseStatus status = _findRequestBlockStatus(exchange, request);
      if (block1.num == 0 && status.currentNUM > 0) {
        // Reset the blockwise transfer
        _log.debug(
            "Block1 num is 0, the client has restarted the blockwise transfer. Reset status.");
        status = new CoapBlockwiseStatus(request.contentType);
        exchange.requestBlockStatus = status;
      }

      if (block1.num == status.currentNUM) {
        if (request.contentType == status.contentFormat) {
          status.addBlock(request.payload);
        } else {
          final CoapResponse error = CoapResponse.createResponse(
              request, CoapCode.requestEntityIncomplete);
          error.addOption(new CoapBlockOption.fromParts(
              optionTypeBlock1, block1.num, block1.szx, block1.m));
          error.setPayload("Changed Content-Format");

          exchange.currentResponse = error;
          super.sendResponse(nextLayer, exchange, error);
          return;
        }

        status.currentNUM = status.currentNUM + 1;
        if (block1.m) {
          _log.debug("There are more blocks to come. Acknowledge this block.");

          final CoapResponse piggybacked =
          CoapResponse.createResponse(request, CoapCode.continues);
          piggybacked.addOption(new CoapBlockOption.fromParts(
              optionTypeBlock1, block1.num, block1.szx, true));
          piggybacked.last = false;

          exchange.currentResponse = piggybacked;
          super.sendResponse(nextLayer, exchange, piggybacked);

          // Do not assemble and deliver the request yet
        } else {
          _log.debug("This was the last block. Deliver request");

          // Remember block to acknowledge.
          exchange.block1ToAck = block1;

          // Block2 early negotiation
          _earlyBlock2Negotiation(exchange, request);

          // Assemble and deliver
          final CoapRequest assembled = new CoapRequest(request.method);
          _assembleMessage(status, assembled, request);

          exchange.request = assembled;
          super.receiveRequest(nextLayer, exchange, assembled);
        }
      } else {
        // ERROR, wrong number, Incomplete
        _log.warn(
            "Wrong block number. Expected ${status
                .currentNUM} but received ${block1
                .num} Respond with 4.08 (Request Entity Incomplete).");
        final CoapResponse error = CoapResponse.createResponse(
            request, CoapCode.requestEntityIncomplete);
        error.addOption(new CoapBlockOption.fromParts(
            optionTypeBlock1, block1.num, block1.szx, block1.m));
        error.setPayload("Wrong block number");
        exchange.currentResponse = error;
        super.sendResponse(nextLayer, exchange, error);
      }
    } else if (exchange.response != null &&
        request.hasOption(optionTypeBlock2)) {
      // The response has already been generated and the client just wants
      // the next block of it
      final CoapBlockOption block2 = request.block2;
      final CoapResponse response = exchange.response;
      final CoapBlockwiseStatus status =
      _findResponseBlockStatus(exchange, response);
      status.currentNUM = block2.num;
      status.currentSZX = block2.szx;

      final CoapResponse block = _getNextResponseBlock(response, status);
      block.token = request.token;
      block.removeOptions(optionTypeObserve);

      if (status.complete) {
        // Clean up blockwise status
        _log.debug("Ongoing is complete $status");
        exchange.responseBlockStatus = null;
        _clearBlockCleanup(exchange);
      } else {
        _log.debug("Ongoing is continuing $status");
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
  void sendResponse(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapResponse response) {
    final CoapBlockOption block1 = exchange.block1ToAck;
    if (block1 != null) {
      exchange.block1ToAck = null;
    }

    if (_requiresBlockwiseExchange(exchange, response)) {
      _log.debug(
          "Response payload ${response
              .payloadSize} / $_maxMessageSize requires Blockwise");

      final CoapBlockwiseStatus status =
      _findResponseBlockStatus(exchange, response);

      final CoapResponse block = _getNextResponseBlock(response, status);

      if (block1 != null) // In case we still have to ack the last block1
        block.setOption(block1);
      if (block.token == null) block.token = exchange.request.token;

      if (status.complete) {
        // Clean up blockwise status
        _log.debug("Ongoing finished on first block $status");
        exchange.responseBlockStatus = null;
        _clearBlockCleanup(exchange);
      } else {
        _log.debug("Ongoing started $status");
      }

      exchange.currentResponse = block;
      super.sendResponse(nextLayer, exchange, block);
    } else {
      if (block1 != null) response.setOption(block1);
      exchange.currentResponse = response;
      // Block1 transfer completed
      _clearBlockCleanup(exchange);
      super.sendResponse(nextLayer, exchange, response);
    }
  }

  @override
  void receiveResponse(CoapINextLayer nextLayer, CoapExchange exchange,
      CoapResponse response) {
    // Do not continue fetching blocks if canceled
    if (exchange.request.isCancelled) {
      // Reject (in particular for Block+Observe)
      if (response.type != CoapMessageType.ack) {
        _log.debug("Rejecting blockwise transfer for canceled Exchange");
        final CoapEmptyMessage rst = CoapEmptyMessage.newRST(response);
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

    final CoapBlockOption block1 = response.block1;
    if (block1 != null) {
      _log.debug("Response acknowledges block $block1");

      final CoapBlockwiseStatus status = exchange.requestBlockStatus;
      if (!status.complete) {
        // Send next block
        final int currentSize = 1 << (4 + status.currentSZX);
        final int nextNum =
        (status.currentNUM + currentSize / block1.size()).toInt();
        _log.debug("Send next block num = $nextNum");
        status.currentNUM = nextNum;
        status.currentSZX = block1.szx;
        final CoapRequest nextBlock =
        _getNextRequestBlock(exchange.request, status);
        if (nextBlock.token == null) {
          nextBlock.token = response.token; // reuse same token
        }
        exchange.currentRequest = nextBlock;
        super.sendRequest(nextLayer, exchange, nextBlock);
        // Do not deliver response
      } else if (!response.hasOption(optionTypeBlock2)) {
        // All request block have been acknowledged and we receive a piggy-backed
        // response that needs no blockwise transfer. Thus, deliver it.
        super.receiveResponse(nextLayer, exchange, response);
      } else {
        _log.debug(
            "Response has Block2 option and is therefore sent blockwise");
      }
    }

    final CoapBlockOption block2 = response.block2;
    if (block2 != null) {
      final CoapBlockwiseStatus status =
      _findResponseBlockStatus(exchange, response);

      if (block2.num == status.currentNUM) {
        // We got the block we expected :-)
        status.addBlock(response.payload);
        final int obs = response.observe;
        if (obs != null) {
          status.observe = obs;
        }

        // Notify blocking progress
        exchange.request.fireResponding(response);

        if (status.isRandomAccess) {
          // The client has requested this specifc block and we deliver it
          exchange.response = response;
          super.receiveResponse(nextLayer, exchange, response);
        } else if (block2.m) {
          _log.debug("Request the next response block");

          final CoapRequest request = exchange.request;
          final int num = block2.num + 1;
          final int szx = block2.szx;
          final bool m = false;

          final CoapRequest block = new CoapRequest(request.method);
          // NON could make sense over SMS or similar transports
          block.type = request.type;
          block.destination = request.destination;
          block.setOptions(request.getSortedOptions());
          block.setOption(
              new CoapBlockOption.fromParts(optionTypeBlock2, num, szx, m));
          // We use the same token to ease traceability (GET without Observe no longer cancels relations)
          block.token = response.token;
          // Make sure not to use Observe for block retrieval
          block.removeOptions(optionTypeObserve);

          status.currentNUM = num;

          exchange.currentRequest = block;
          super.sendRequest(nextLayer, exchange, block);
        } else {
          _log.debug(
              "We have received all ${status
                  .blockCount} blocks of the response. Assemble and deliver.");
          final CoapResponse assembled = new CoapResponse(response.statusCode);
          _assembleMessage(status, assembled, response);
          assembled.type = response.type;

          // Set overall transfer RTT
          assembled.rtt = (new DateTime.now().difference(exchange.timestamp))
              .inMilliseconds
              .toDouble();

          // Check if this response is a notification
          final int observe = status.observe;
          if (observe != CoapBlockwiseStatus.noObserve) {
            assembled
                .addOption(CoapOption.createVal(optionTypeObserve, observe));
            // This is necessary for notifications that are sent blockwise:
            // Reset block number AND container with all blocks
            exchange.responseBlockStatus = null;
          }

          _log.debug("Assembled response: $assembled");
          exchange.response = assembled;
          super.receiveResponse(nextLayer, exchange, assembled);
        }
      } else {
        // ERROR, wrong block number (server error)
        // Currently, we reject it and cancel the request.
        _log.warn(
            "Wrong block number. Expected ${status
                .currentNUM} but received ${block2
                .num}. Reject response; exchange has failed.");
        if (response.type == CoapMessageType.con) {
          final CoapEmptyMessage rst = CoapEmptyMessage.newRST(response);
          super.sendEmptyMessage(nextLayer, exchange, rst);
        }
        exchange.request.isCancelled = true;
      }
    }
  }

  bool _requiresBlockwise(CoapRequest request) {
    if (request.method == CoapCode.methodPUT ||
        request.method == CoapCode.methodPOST)
      return request.payloadSize > _maxMessageSize;
    else
      return false;
  }

  CoapBlockwiseStatus _findRequestBlockStatus(CoapExchange exchange,
      CoapRequest request) {
    CoapBlockwiseStatus status = exchange.requestBlockStatus;
    if (status == null) {
      status = new CoapBlockwiseStatus(request.contentType);
      status.currentSZX = CoapBlockOption.encodeSZX(_defaultBlockSize);
      exchange.requestBlockStatus = status;
      _log.debug(
          "There is no assembler status yet. Create and set new Block1 status: $status");
    } else {
      _log.debug("Current Block1 status: $status");
    }
    // sets a timeout to complete exchange
    _prepareBlockCleanup(exchange);
    return status;
  }

  CoapRequest _getNextRequestBlock(CoapRequest request,
      CoapBlockwiseStatus status) {
    final int num = status.currentNUM;
    final int szx = status.currentSZX;
    final CoapRequest block = new CoapRequest(request.method);
    block.setOptions(request.getSortedOptions());
    block.destination = request.destination;
    block.token = request.token;
    block.type = CoapMessageType.con;

    final int currentSize = 1 << (4 + szx);
    final int from = num * currentSize;
    final int to = min((num + 1) * currentSize, request.payloadSize);
    final int length = to - from;
    final typed.Uint8Buffer blockPayload = new typed.Uint8Buffer()
      ..addAll(request.payload.getRange(from, from + length));
    block.payload = blockPayload;

    final bool m = to < request.payloadSize;
    block.addOption(
        new CoapBlockOption.fromParts(optionTypeBlock1, num, szx, m));

    status.complete = !m;
    return block;
  }

  void _earlyBlock2Negotiation(CoapExchange exchange, CoapRequest request) {
    // Call this method when a request has completely arrived (might have
    // been sent in one piece without blockwise).
    if (request.hasOption(optionTypeBlock2)) {
      final CoapBlockOption block2 = request.block2;
      final CoapBlockwiseStatus status2 = new CoapBlockwiseStatus.withSize(
          request.contentType, block2.num, block2.szx);
      _log.debug(
          "Request with early block negotiation $block2. Create and set new Block2 status: $status2");
      exchange.responseBlockStatus = status2;
    }
  }

  void _assembleMessage(CoapBlockwiseStatus status, CoapMessage message,
      CoapMessage last) {
    // The assembled request will contain the options of the last block
    message.id = last.id;
    message.source = last.source;
    message.token = last.token;
    message.type = last.type;
    message.setOptions(last.getSortedOptions());

    final typed.Uint8Buffer payload = new typed.Uint8Buffer();
    for (typed.Uint8Buffer block in status.blocks) {
      payload.addAll(block);
    }
    message.payload = payload;
  }

  CoapBlockwiseStatus _findResponseBlockStatus(CoapExchange exchange,
      CoapResponse response) {
    final CoapBlockwiseStatus status = exchange.responseBlockStatus;
    if (status == null) {
      final status = new CoapBlockwiseStatus(response.contentType);
      status.currentSZX = CoapBlockOption.encodeSZX(_defaultBlockSize);
      exchange.responseBlockStatus = status;
      _log.debug(
          "There is no blockwise status yet. Create and set new Block2 status: $status");
    } else {
      _log.debug("Current Block2 status: $status");
    }

    // Sets a timeout to complete exchange
    _prepareBlockCleanup(exchange);
    return status;
  }

  CoapResponse _getNextResponseBlock(CoapResponse response,
      CoapBlockwiseStatus status) {
    CoapResponse block;
    final int szx = status.currentSZX;
    final int num = status.currentNUM;

    if (response.hasOption(optionTypeObserve)) {
      // A blockwise notification transmits the first block only
      block = response;
    } else {
      block = new CoapResponse(response.statusCode);
      block.destination = response.destination;
      block.token = response.token;
      block.setOptions(response.getSortedOptions());
      block.isTimedOut = true;
    }

    final int payloadSize = response.payloadSize;
    final int currentSize = 1 << (4 + szx);
    final int from = num * currentSize;
    if (payloadSize > 0 && payloadSize > from) {
      final int to = min((num + 1) * currentSize, response.payloadSize);
      final int length = to - from;
      final typed.Uint8Buffer blockPayload = new typed.Uint8Buffer();
      final bool m = to < response.payloadSize;
      block.setBlock2(szx, m, num);

      // Crop payload -- do after calculation of m in case block==response
      blockPayload.addAll(response.payload.getRange(from, from + length));
      block.payload = blockPayload;

      // Do not complete notifications
      block.last = !m && !response.hasOption(optionTypeObserve);

      status.complete = !m;
    } else {
      block.addOption(
          new CoapBlockOption.fromParts(optionTypeBlock2, num, szx, false));
      block.last = true;
      status.complete = true;
    }

    return block;
  }

  /// Schedules a clean-up task.
  void _prepareBlockCleanup(CoapExchange exchange) {
    final Timer timer = new Timer(new Duration(milliseconds: _blockTimeout),
            () => _blockwiseTimeout(exchange));
    final Timer old = exchange.set("BlockCleanupTimer", timer);
    old?.cancel();
  }

  /// Clears the clean-up task.
  void _clearBlockCleanup(CoapExchange exchange) {
    final Timer timer = exchange.remove("BlockCleanupTimer");
    timer?.cancel();
  }

  void _blockwiseTimeout(CoapExchange exchange) {
    if (exchange.request == null) {
      _log.info("Block1 transfer timed out: $exchange.currentRequest");
    } else {
      _log.info("Block2 transfer timed out: $exchange.request");
    }
    exchange.complete = true;
  }

  bool _requiresBlockwiseExchange(CoapExchange exchange,
      CoapResponse response) {
    return response.payloadSize > _maxMessageSize ||
        exchange.responseBlockStatus != null;
  }
}