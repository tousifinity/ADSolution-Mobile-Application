import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class MapPage extends StatefulWidget {
  final double latitude;
  final double longitude;

  MapPage({required this.latitude, required this.longitude});

  // Define your home location coordinates
  static const double homeLatitude = 23.7993225; // Example home latitude
  static const double homeLongitude = 90.3483706; // Example home longitude

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<LatLng> _routePoints = [];
  double _distanceInKm = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    final osrmUrl =
        'http://router.project-osrm.org/route/v1/driving/${MapPage.homeLongitude},${MapPage.homeLatitude};${widget.longitude},${widget.latitude}?geometries=geojson';

    final response = await http.get(Uri.parse(osrmUrl));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> routes = data['routes'];
      final route = routes.isNotEmpty ? routes[0] : null;

      if (route != null) {
        final List<dynamic> geometry = route['geometry']['coordinates'];
        setState(() {
          _routePoints = geometry
              .map((point) => LatLng(point[1] as double, point[0] as double))
              .toList();
          _calculateDistance();
        });
      }
    } else {
      throw Exception('Failed to fetch route');
    }
  }

  void _calculateDistance() {
    final Distance distance = Distance();
    double totalDistance = 0.0;
    for (int i = 0; i < _routePoints.length - 1; i++) {
      totalDistance += distance(
        _routePoints[i],
        _routePoints[i + 1],
      );
    }
    setState(() {
      _distanceInKm = totalDistance / 1000; // Convert meters to kilometers
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Page'),
      ),
      body: Column(
        children: [
          Flexible(
            child: FlutterMap(
              options: MapOptions(
                center: LatLng(MapPage.homeLatitude, MapPage.homeLongitude),
                zoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blue,
                      strokeWidth: 4,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point:
                          LatLng(MapPage.homeLatitude, MapPage.homeLongitude),
                      builder: (ctx) => Container(
                        child: Icon(
                          Icons.home,
                          color: Colors.green,
                          size: 40,
                        ),
                      ),
                    ),
                    Marker(
                      point: LatLng(widget.latitude, widget.longitude),
                      builder: (ctx) => Container(
                        child: Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Distance: ${_distanceInKm.toStringAsFixed(2)} km',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
