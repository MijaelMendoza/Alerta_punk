import 'dart:ui' as ui;
import 'package:alerta_punk/pages/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SaveAreaPage extends StatefulWidget {
  final List<LatLng> points;
  final LatLng centroid;

  const SaveAreaPage({Key? key, required this.points, required this.centroid})
      : super(key: key);

  @override
  _SaveAreaPageState createState() => _SaveAreaPageState();
}

class _SaveAreaPageState extends State<SaveAreaPage> {
  Color _selectedColor = Colors.blue;
  String _areaName = '';
  Set<Polygon> _polygons = {};
  Set<Marker> _markers = {};
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initializePolygonAndMarkers();
    _getUserId();
  }

  Future<void> _getUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
    }
  }

  void _initializePolygonAndMarkers() {
    _polygons = {
      Polygon(
        polygonId: const PolygonId('area'),
        points: widget.points,
        strokeColor: Colors.black,
        strokeWidth: 3,
        fillColor: _selectedColor.withOpacity(0.3),
      ),
    };

    _createCustomMarkers().then((markers) {
      setState(() {
        _markers = markers;
      });
    });
  }

  Future<Set<Marker>> _createCustomMarkers() async {
    final List<Marker> customMarkers = [];
    for (var point in widget.points) {
      final icon = await _createColoredMarker(_selectedColor);
      customMarkers.add(
        Marker(
          markerId: MarkerId(point.toString()),
          position: point,
          icon: icon,
        ),
      );
    }
    return customMarkers.toSet();
  }

  Future<BitmapDescriptor> _createColoredMarker(Color color) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guardar Área de Interés')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Mapa no interactivo
            Expanded(
              flex: 2,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: widget.centroid,
                  zoom: 15,
                ),
                markers: _markers,
                polygons: _polygons,
                myLocationEnabled: false,
                zoomControlsEnabled: false,
                scrollGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                zoomGesturesEnabled: false,
              ),
            ),
            const SizedBox(height: 20),

            // Campo de texto para el nombre del área
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nombre del Área',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _areaName = value;
                });
              },
            ),
            const SizedBox(height: 20),

            // Selector de color
            Row(
              children: [
                const Text('Color del Área: ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    _showColorPicker(context);
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),

            // Botón para guardar
            ElevatedButton(
              onPressed: _saveToDatabase,
              child: const Text('Guardar Área'),
            ),
          ],
        ),
      ),
    );
  }

  // Mostrar selector de color
  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar Color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                  _updatePolygonAndMarkers();
                });
              },
            ),
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

  // Actualizar el color del polígono y los marcadores
  void _updatePolygonAndMarkers() {
    setState(() {
      _polygons = {
        Polygon(
          polygonId: const PolygonId('area'),
          points: widget.points,
          strokeColor: Colors.black,
          strokeWidth: 3,
          fillColor: _selectedColor.withOpacity(0.3),
        ),
      };

      _createCustomMarkers().then((markers) {
        setState(() {
          _markers = markers;
        });
      });
    });
  }

  // Guardar el área en Firebase
  Future<void> _saveToDatabase() async {
    if (_areaName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa el nombre del área.')),
      );
      return;
    }

    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no autenticado.')),
      );
      return;
    }

    final areaData = {
      'userId': _userId,
      'name': _areaName,
      'color': _selectedColor.value.toRadixString(16),
      'centroid': {
        'latitude': widget.centroid.latitude,
        'longitude': widget.centroid.longitude,
      },
      'points': widget.points
          .map((point) =>
              {'latitude': point.latitude, 'longitude': point.longitude})
          .toList(),
    };

    try {
      await FirebaseFirestore.instance.collection('areas').add(areaData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Área guardada exitosamente.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el área: $e')),
      );
    }
  }
}
