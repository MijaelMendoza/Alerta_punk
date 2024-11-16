import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController _mapController;
  final Location _location = Location();
  LatLng _initialLocation = const LatLng(-16.0, -68);

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    final hasPermission = await _checkLocationPermission();

    if (hasPermission) {
      final userLocation = await _location.getLocation();
      setState(() {
        _initialLocation =
            LatLng(userLocation.latitude!, userLocation.longitude!);
      });
      _mapController.moveCamera(
        CameraUpdate.newLatLng(_initialLocation),
      );
    }
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return false;
      }
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialLocation,
          zoom: 17,
        ),
        myLocationEnabled: true, // Habilitar icono de ubicación
        myLocationButtonEnabled: true, // Botón para centrar la ubicación
        zoomControlsEnabled: false, // Deshabilitar botones de zoom
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
      ),
    );
  }
}
