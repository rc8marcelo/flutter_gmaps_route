import 'package:flutter/material.dart';
import 'package:google_maps_apis/directions.dart' as d;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import "package:google_maps_apis/geocoding.dart";

final geocoding = GoogleMapsGeocoding(apiKey: "<GOOGLE_API_KEY>");
final directions = d.GoogleMapsDirections(apiKey: "<GOOGLE_API_KEY>");

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  GoogleMapController? mapController;
  List<LatLng> polylineCoordinates = [];
  Set<Polyline> polylines = {};

  Future<void> getDirections(String origin, String destination) async {
    final response = await directions.directionsWithAddress(
      origin,
      destination,
      travelMode: TravelMode.driving,
    );

    if (response.isOk) {
      final route = response.routes?.first;
      final polyline = route?.overviewPolyline!.points;
      final points = _decodePolyline(polyline!);
      setState(() {
        polylineCoordinates = points;
        polylines.add(Polyline(
          polylineId: const PolylineId('route'),
          visible: true,
          points: polylineCoordinates,
          color: Colors.blue,
          width: 5,
        ));
      });
    } else {
      //error
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  mapController = controller;
                },
                initialCameraPosition: const CameraPosition(
                  target: LatLng(14.466576, 121.016050),
                  zoom: 12,
                ),
                mapType: MapType.normal,
                polylines: polylines,
              ),
            ),
            TextButton(
              onPressed: () async {
                await getDirections(
                    'Sydney, Australia', 'Melbourne, Australia');
              },
              child: const Text('Get Directions'),
            ),
          ],
        ),
      ),
    );
  }
}
