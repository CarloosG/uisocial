// map_page.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatelessWidget {
  final String eventName;
  final String location; // O lat/lng si lo tienes separado

  const MapPage({super.key, required this.eventName, required this.location});

  @override
  Widget build(BuildContext context) {
    double lat = 0;
    double lng = 0;

    if (location.isNotEmpty && location.contains(',')) {
      final parts = location.split(',');
      if (parts.length == 2) {
        lat = double.tryParse(parts[0]) ?? 0;
        lng = double.tryParse(parts[1]) ?? 0;
      }
    }

    // Asignar coordenadas por defecto si no se pudo parsear la ubicación
    if (lat == 0 && lng == 0) {
      lat = 7.119349; // Ejemplo: latitud UIS
      lng = -73.122741; // Ejemplo: longitud UIS
    }

    return Scaffold(
      appBar: AppBar(title: Text(eventName)),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(lat, lng),
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('event'),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(title: eventName),
          ),
        },
      ),
    );
  }
}
