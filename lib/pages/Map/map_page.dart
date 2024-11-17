import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  Set<Polygon> _polygons = {}; // Polígonos que se dibujarán en el mapa
  Set<Marker> _markers = {}; // Marcadores personalizados para los puntos del área

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _loadUserAreas(); // Cargar áreas guardadas
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

  Future<BitmapDescriptor> _createCustomMarker(Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 50.0;

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  Future<void> _loadUserAreas() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado')),
      );
      return;
    }

    try {
      // Obtener las áreas desde Firebase filtradas por UID
      final areasSnapshot = await FirebaseFirestore.instance
          .collection('areas')
          .where('userId', isEqualTo: user.uid)
          .get();

      final Set<Polygon> userPolygons = {};
      final Set<Marker> userMarkers = {};

      for (var doc in areasSnapshot.docs) {
        final data = doc.data();
        final List<dynamic> pointsData = data['points'];
        final String colorHex = data['color'];
        final String name = data['name'];
        final Map<String, dynamic> centroidData = data['centroid'];
        final color = Color(int.parse('0xff$colorHex'));

        final List<LatLng> points = pointsData
            .map((point) => LatLng(point['latitude'], point['longitude']))
            .toList()
            .cast<LatLng>();

        // Crear polígono
        userPolygons.add(
          Polygon(
            polygonId: PolygonId(doc.id),
            points: points,
            strokeColor: Colors.black,
            strokeWidth: 3,
            fillColor: color.withOpacity(0.3),
            onTap: () {
              _showAreaInfoDialog(name, color, centroidData);
            },
          ),
        );

        // Crear marcadores personalizados para cada punto
        for (var point in points) {
          final icon = await _createCustomMarker(color);
          userMarkers.add(
            Marker(
              markerId: MarkerId(point.toString()),
              position: point,
              icon: icon,
            ),
          );
        }
      }

      setState(() {
        _polygons = userPolygons;
        _markers = userMarkers;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar áreas: $e')),
      );
    }
  }

  void _showAreaInfoDialog(
      String name, Color color, Map<String, dynamic> centroidData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Información del Área'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nombre: $name'),
              Text('Color: ${color.toString()}'),
              Text(
                  'Centroide: (${centroidData['latitude']}, ${centroidData['longitude']})'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialLocation,
          zoom: 15,
        ),
        myLocationEnabled: true, // Habilitar icono de ubicación
        myLocationButtonEnabled: true, // Botón para centrar la ubicación
        zoomControlsEnabled: false, // Deshabilitar botones de zoom
        polygons: _polygons, // Dibujar los polígonos en el mapa
        markers: _markers, // Dibujar los marcadores personalizados
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
      ),
    );
  }
}
