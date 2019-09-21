/*
 * Package : Coap
 * Author : S. Hamblett <steve.hamblett@linux.com>
 * Date   : 03/05/2017
 * Copyright :  S.Hamblett
 */

part of coap;

/// This class describes the CoAP Code Registry as defined in
/// draft-ietf-core-coap-08, section 11.1
class CoapCode {
  /// Not set
  static const int notSet = -1;

  /// Empty
  static const int empty = 0;

  /// Success
  static const int successCode = 2;

  /// Client error
  static const int clientErrorCode = 4;

  /// Server error
  static const int serverErrorCode = 5;

  /// Method Codes

  /// The GET method
  static const int get = 1;

  /// The POST method
  static const int post = 2;

  /// The PUT method
  static const int put = 3;

  /// The DELETE method
  static const int delete = 4;

  /// Response Codes

  /// 2.01 Created
  static const int created = 65;

  /// 2.02 Deleted
  static const int deleted = 66;

  /// 2.03 Valid
  static const int valid = 67;

  /// 2.04 Changed
  static const int changed = 68;

  /// 2.05 Content
  static const int content = 69;

  /// 2.?? Continue
  static const int continues = 95;

  /// 4.00 Bad Request
  static const int badRequest = 128;

  /// 4.01 Unauthorized
  static const int unauthorized = 129;

  /// 4.02 Bad Option
  static const int badOption = 130;

  /// 4.03 Forbidden
  static const int forbidden = 131;

  /// 4.04 Not Found
  static const int notFound = 132;

  /// 4.05 Method Not Allowed
  static const int methodNotAllowed = 133;

  /// 4.06 Not Acceptable
  static const int notAcceptable = 134;

  /// 4.08 Request Entity Incomplete (draft-ietf-core-block)
  static const int requestEntityIncomplete = 136;

  /// 4.12 Client not supported by server/headers don't satisfy protocol
  static const int preconditionFailed = 140;

  /// 4.13 Request Entity Too Large
  static const int requestEntityTooLarge = 141;

  /// 4.15 Unsupported Media Type
  static const int unsupportedMediaType = 143;

  /// 5.00 Internal Server Error
  static const int internalServerError = 160;

  /// 5.01 Not Implemented
  static const int notImplemented = 161;

  /// 5.02 Bad Gateway
  static const int badGateway = 162;

  /// 5.03 Service Unavailable
  static const int serviceUnavailable = 163;

  /// 5.04 Gateway Timeout
  static const int gatewayTimeout = 164;

  /// 5.05 Proxying Not Supported
  static const int proxyingNotSupported = 165;

  /// Gets the response class
  static int getResponseClass(int code) => code >> 5 & 0x7;

  /// Checks whether a code indicates a request
  /// Returns true iff the code indicates a request
  static bool isRequest(int code) => (code >= 1) && (code <= 31);

  /// Checks whether a code indicates a response
  /// Returns true iff the code indicates a response
  static bool isResponse(int code) => (code >= 64) && (code <= 191);

  /// Checks whether a code indicates an empty message
  /// Returns true iff the code indicates an empty message
  static bool isEmpty(int code) => code == 0;

  /// Checks whether a code represents a success code.
  static bool isSuccess(int code) => code >= 64 && code < 96;

  /// Checks whether a code is valid
  /// Returns true iff the code is valid
  static bool isValid(int code) =>
      (code >= 0) && (code <= 255); // allow unknown custom codes;

  /// Returns a string representation of the code
  static String codeToString(int code) {
    if (code == null) {
      return 'Null status code';
    }
    switch (code) {
      case notSet:
        return 'Not Set';
      case empty:
        return 'Empty Message';
      case get:
        return 'GET';
      case post:
        return 'POST';
      case put:
        return 'PUT';
      case delete:
        return 'DELETE';
      case created:
        return '2.01 Created';
      case deleted:
        return '2.02 Deleted';
      case valid:
        return '2.03 Valid';
      case changed:
        return '2.04 Changed';
      case content:
        return '2.05 Content';
      case badRequest:
        return '4.00 Bad Request';
      case unauthorized:
        return '4.01 Unauthorized';
      case badOption:
        return '4.02 Bad Option';
      case forbidden:
        return '4.03 Forbidden';
      case notFound:
        return '4.04 Not Found';
      case methodNotAllowed:
        return '4.05 Method Not Allowed';
      case notAcceptable:
        return '4.06 Not Acceptable';
      case requestEntityIncomplete:
        return '4.08 Request Entity Incomplete';
      case preconditionFailed:
        return '4.12 Precondition Failed';
      case requestEntityTooLarge:
        return '4.13 Request Entity Too Large';
      case unsupportedMediaType:
        return '4.15 Unsupported Media Type';
      case internalServerError:
        return '5.00 Internal Server Error';
      case notImplemented:
        return '5.01 Not Implemented';
      case badGateway:
        return '5.02 Bad Gateway';
      case serviceUnavailable:
        return '5.03 Service Unavailable';
      case gatewayTimeout:
        return '5.04 Gateway Timeout';
      case proxyingNotSupported:
        return '5.05 Proxying Not Supported';
      default:
        break;
    }

    if (isValid(code)) {
      if (isRequest(code)) {
        return 'Unknown Request [code {0}]';
      } else if (isResponse(code)) {
        return 'Unknown Response [code {0}]';
      } else {
        return 'Reserved [code {0}]';
      }
    } else {
      return 'Invalid Message [code {0}]';
    }
  }

  /// Methods of request

  /// GET
  static int methodGET = 1;

  /// POST
  static int methodPOST = 2;

  /// PUT
  static int methodPUT = 3;

  /// DELETE
  static int methodDELETE = 4;

  /// Response status codes.

  /// 2.01 Created
  static const int statusCodeCreated = 65;

  /// 2.02 Deleted
  static const int statusCodeDeleted = 66;

  /// 2.03 Valid
  static const int statusCodeValid = 67;

  /// 2.04 Changed
  static const int statusCodeChanged = 68;

  /// 2.05 Content
  static const int statusCodeContent = 69;

  /// 2.?? Continue
  static const int statusCodeContinue = 95;

  /// 4.00 Bad Request
  static const int statusCodeBadRequest = 128;

  /// 4.01 Unauthorized
  static const int statusCodeUnauthorized = 129;

  /// 4.02 Bad Option
  static const int statusCodeBadOption = 130;

  /// 4.03 Forbidden
  static const int statusCodeForbidden = 131;

  /// 4.04 Not Found
  static const int statusCodeNotFound = 132;

  /// 4.05 Method Not Allowed
  static const int statusCodeMethodNotAllowed = 133;

  /// 4.06 Not Acceptable
  static const int statusCodeNotAcceptable = 134;

  /// 4.08 Request Entity Incomplete (draft-ietf-core-block)
  static const int statusCodeRequestEntityIncomplete = 136;

  /// 4.12 Precondition failed
  static const int statusCodePreconditionFailed = 140;

  /// 4.13 Request Entity Too Large
  static const int statusCodeRequestEntityTooLarge = 141;

  /// 4.15 Unsupported Media Type
  static const int statusCodeUnsupportedMediaType = 143;

  /// 5.00 Internal Server Error
  static const int statusCodeInternalServerError = 160;

  /// 5.01 Not Implemented
  static const int statusCodeNotImplemented = 161;

  /// 5.02 Bad Gateway
  static const int statusCodeBadGateway = 162;

  /// 5.03 Service Unavailable
  static const int statusCodeServiceUnavailable = 163;

  /// 5.04 Gateway Timeout
  static const int statusCodeGatewayTimeout = 164;

  /// 5.05 Proxying Not Supported
  static const int statusCodeProxyingNotSupported = 165;
}
