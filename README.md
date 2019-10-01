# coap

A CoAP client library for Dart developers.

The Constrained Application Protocol ([CoAP](https://datatracker.ietf.org/doc/draft-ietf-core-coap/)) 
is a RESTful web transfer protocol for resource-constrained networks and nodes.

COAP is an implementation in Dart providing CoAP-based services to Dart applications. 

The code is a port from the C# .NET project [CoAP.NET](https://github.com/smeshlink/CoAP.NET). The dart implementation is that
of a CoAP client only, not a server although the CoAP.NET project does supply a server.

The COAP client provides many high level functions to control the request/response nature of the CoAP protocol, 
fine grained control however can be obtained by users directly constructing their own request messages. 

Configuration is achieved by editing a yaml based config file containing many of CoAP protocol configurations.

This is a full implementation of the CoAP protocol including block wise transfer, deduplication, transmission retries using
request/response matching etc.. Proxying options can be set in request messages however full proxying support is
 not guaranteed. Observation of resources is supported with the client 'listening' for observed resource updates 
 when configured for this. The client supports both IPV4 and IPV6 communications and multicast operation. CoAP over TLS
 over DTLS(secure CoAP) is not supported.

Many examples of usage are provided in the examples directory both using a .NET based CoAP server for local testing
and testing using the coap.me (http://coap.me/) test server. Also a fully populated default configuration
file is present in the examples directory.

