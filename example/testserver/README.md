This directory contains a simple .NET based CoAP test server to use with the examples.
Windows only unfortunately as its .NET based.
It returns the following resource links :-

``````
</fibonacci> 
</storage> 
</careless> 
	title:	"This resource will ACK anything, but never send a separate response"
	rt:	["SepararateResponseTester"]
</large> 
	title:	"This is a large resource for testing block-wise transfer"
	rt:	["BlockWiseTransferTester"]
</image> 
	title:	"GET an image with different content-types"
	rt:	["Image"]
	ct:	["22 23"]
	sz:	18029
</hello> 
	title:	"GET a friendly greeting!"
	rt:	["HelloWorldDisplayer"]
</.well-known/core> 
</separate> 
	title:	"GET a response in a separate CoAP Message"
	rt:	["SepararateResponseTester"]
</time> 
	title:	"GET the current time"
	rt:	["CurrentTime"]
	obs
</mirror> 
``````
You can use these as path examples in any testing you do for intance the time path returns as it says the current time and is observable.
