import 'package:coap/coap.dart';
import 'package:flutter/material.dart';
import 'config/coap_config.dart';

// ignore: unnecessary_final, omit_local_variable_types
// ignore: public_member_api_docs, always_specify_types

void main() => runApp(MyApp());

/// make linter happy
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

/// make linter happy
class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _data;
  bool _isLoading = false;

  final config = CoapConfig();
  final host = 'coap.me';

  Future<void> _loadData() async {
    final Uri uri = Uri(scheme: 'coap', host: host, port: config.defaultPort);

    // Client
    final CoapClient client = CoapClient(uri, config);

    // Create the request for the get request
    final CoapRequest request = CoapRequest.newGet();
    request.addUriPath('hello');
    client.request = request;

    setState(() => _isLoading = true);

    final CoapResponse response = await client.get();

    setState(() {
      _isLoading = false;
      _data = response.payloadString ?? 'No Data';
    });

    client.close();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Flutter CoAP'),
      ),
      body: Center(
        child: Builder(
          builder: (_) {
            if (_isLoading) {
              return const CircularProgressIndicator();
            }

            if (_data != null) {
              return Text('Response:\n $_data',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18)
              );
            }
            return const Text('Press the button to load data');
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        tooltip: 'Load',
        child: Icon(Icons.cloud_download),
      ),
    );
}
