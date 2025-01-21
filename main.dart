import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'dart:convert';
import 'package:network_info_plus/network_info_plus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Map Navigation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ServerClientSelector(),
    );
  }
}

class ServerClientSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Server/Client Mode'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ServerApp()),
              ),
              child: Text('Run as Server'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ClientApp()),
              ),
              child: Text('Run as Client'),
            ),
          ],
        ),
      ),
    );
  }
}

class ServerApp extends StatefulWidget {
  @override
  _ServerAppState createState() => _ServerAppState();
}

class _ServerAppState extends State<ServerApp> {
  HttpServer? server;
  Timer? timer;
  double latitude = 37.7749;
  double longitude = -122.4194;

  @override
  void initState() {
    super.initState();
    startServer();
  }

  Future<void> startServer() async {
    server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
    server?.listen((HttpRequest request) {
      if (request.method == 'GET') {
        final location = jsonEncode({'latitude': latitude, 'longitude': longitude});
        request.response
          ..statusCode = HttpStatus.ok
          ..write(location)
          ..close();
      }
    });

    timer = Timer.periodic(Duration(seconds: 5), (timer) {
      setState(() {
        latitude += 0.0001; // Simulate movement
        longitude += 0.0001;
      });
    });
  }

  @override
  void dispose() {
    server?.close();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Server Mode'),
      ),
      body: Center(
        child: Text('Server is running on port 8080\nLatitude: $latitude\nLongitude: $longitude'),
      ),
    );
  }
}

class ClientApp extends StatefulWidget {
  @override
  _ClientAppState createState() => _ClientAppState();
}

class _ClientAppState extends State<ClientApp> {
  final MapController mapController = MapController();
  LatLng currentLocation = LatLng(37.7749, -122.4194);

  @override
  void initState() {
    super.initState();
    fetchLocation();
  }

  Future<String> getDefaultGateway() async {
    final info = NetworkInfo();
    final gateway = await info.getWifiGatewayIP();
    if (gateway != null) {
      return gateway;
    } else {
      throw Exception('Default Gateway not found');
    }
  }

  Future<void> fetchLocation() async {
    String serverIP;
    try {
      serverIP = await getDefaultGateway();
    } catch (e) {
      print('Error getting default gateway: $e');
      return;
    }

    Timer.periodic(Duration(seconds: 5), (timer) async {
      try {
        final response = await HttpClient().getUrl(Uri.parse('http://$serverIP:8080'));
        final result = await response.close();
        if (result.statusCode == HttpStatus.ok) {
          final jsonData = await result.transform(utf8.decoder).join();
          final data = jsonDecode(jsonData);
          setState(() {
            currentLocation = LatLng(data['latitude'], data['longitude']);
            mapController.move(currentLocation, mapController.zoom);
          });
        }
      } catch (e) {
        print('Error fetching location: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Client Mode'),
      ),
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          center: currentLocation,
          zoom: 13.0,
        ),
        layers: [
          TileLayerOptions(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayerOptions(
            markers: [
              Marker(
                width: 80.0,
                height: 80.0,
                point: currentLocation,
                builder: (ctx) => Icon(Icons.location_on, color: Colors.red, size: 40),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
