# coap

A CoAP library for Dart developers.

The Constrained Application Protocol (CoAP) (https://datatracker.ietf.org/doc/draft-ietf-core-coap/)
is a RESTful web transfer protocol for resource-constrained networks and nodes.
COAP is an implementation in Dart providing CoAP-based services to Dart applications. 
The code is a port from the C# .NET project CoAP.NET (https://github.com/smeshlink/CoAP.NET).

The COAP client provides many high level functions to control the request/response nature of the CoAP protocol, 
fine grained control however can be obtained by users directly constructing their own request messages. 

Configuration is achieved by editing a yaml based config file containing many of CoAP protocol configurations.

This is a full implementation of the CoAP protocol including blockwise transfer, deduplication etc.

Many examples of usage are provided in the examples directory both using a .NET based CoAP server for local testing
and testing using the coap.me (http://coap.me/) test server.

