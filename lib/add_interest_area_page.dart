import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'env/env.dart'; // Archivo que contiene la clave de la API de Google.
import 'save_area_page.dart';

class AddInterestAreaPage extends StatefulWidget {
  const AddInterestAreaPage({Key? key}) : super(key: key);

  @override
  _AddInterestAreaPageState createState() => _AddInterestAreaPageState();
}

class _AddInterestAreaPageState extends State<AddInterestAreaPage> {
  final List<LatLng> _polygonPoints = [];
  final List<Marker> _markers = [];
  final List<Polygon> _polygons = [];
  GoogleMapController? mapController;
  LatLng? userLocation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor habilita los servicios de ubicación'),
        ),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permisos de ubicación denegados'),
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Los permisos de ubicación están denegados permanentemente'),
        ),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      userLocation = LatLng(position.latitude, position.longitude);
    });

    mapController?.animateCamera(CameraUpdate.newLatLngZoom(userLocation!, 15));
  }

  Future<BitmapDescriptor> _createCustomMarker() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 80;

    final Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(uint8List);
  }

  void _onMapTapped(LatLng position) async {
    final existingIndex = _polygonPoints.indexWhere((point) =>
        (point.latitude - position.latitude).abs() < 1e-6 &&
        (point.longitude - position.longitude).abs() < 1e-6);

    if (existingIndex != -1) {
      // Si el punto ya existe, eliminarlo correctamente
      setState(() {
        _polygonPoints.removeAt(existingIndex);
        _markers.removeAt(existingIndex);
        _reorderPolygon(); // Reordenar después de eliminar
      });
    } else {
      // Si no existe, agregar un nuevo punto
      final customIcon = await _createCustomMarker();
      setState(() {
        _polygonPoints.add(position);
        _markers.add(
          Marker(
            markerId: MarkerId(position.toString()),
            position: position,
            icon: customIcon,
            onTap: () {
              _onMapTapped(position);
            },
          ),
        );
        _reorderPolygon(); // Reordenar después de agregar
      });
    }
  }

  void _reorderPolygon() {
    if (_polygonPoints.length > 2) {
      final LatLng centroid = _calculateCentroid(_polygonPoints);

      // Calcular ángulos para cada punto
      final List<Map<String, dynamic>> pointsWithAngles = List.generate(
        _polygonPoints.length,
        (index) => {
          'point': _polygonPoints[index],
          'marker': _markers[index],
          'angle': _calculateAngle(centroid, _polygonPoints[index]),
        },
      );

      // Ordenar por ángulo en sentido antihorario
      pointsWithAngles.sort((a, b) => a['angle'].compareTo(b['angle']));

      // Actualizar _polygonPoints y _markers en el nuevo orden
      _polygonPoints
        ..clear()
        ..addAll(pointsWithAngles.map((entry) => entry['point'] as LatLng));
      _markers
        ..clear()
        ..addAll(pointsWithAngles.map((entry) => entry['marker'] as Marker));
    }
    _updatePolygon();
  }

  double _calculateAngle(LatLng center, LatLng point) {
    return atan2(point.longitude - center.longitude, point.latitude - center.latitude);
  }

  void _updatePolygon() {
    if (_polygonPoints.isNotEmpty) {
      final polygon = Polygon(
        polygonId: const PolygonId('polygon'),
        points: _polygonPoints,
        strokeColor: Colors.black,
        strokeWidth: 3,
        fillColor: Colors.blue.withOpacity(0.3),
      );
      _polygons.clear();
      _polygons.add(polygon);
    }
    setState(() {});
  }

  Future<void> _searchPlace(String query) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&key=$googleAPIKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          final place = data['results'][0];
          final lat = place['geometry']['location']['lat'];
          final lng = place['geometry']['location']['lng'];

          final LatLng placeLatLng = LatLng(lat, lng);

          mapController?.animateCamera(CameraUpdate.newLatLngZoom(placeLatLng, 15));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lugar no encontrado')),
          );
        }
      } else {
        throw Exception('Error en la API de Google Places');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al buscar lugar: $e')),
      );
    }
  }

  void _saveArea() {
    if (_polygonPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecciona al menos 3 puntos para crear un área')),
      );
      return;
    }

    LatLng centroid = _calculateCentroid(_polygonPoints);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SaveAreaPage(
          points: _polygonPoints,
          centroid: centroid,
        ),
      ),
    );
  }

  LatLng _calculateCentroid(List<LatLng> points) {
    double latSum = 0.0;
    double lngSum = 0.0;

    for (var point in points) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }

    return LatLng(latSum / points.length, lngSum / points.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Área de Interés'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveArea,
          ),
        ],
      ),
      body: userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar lugar',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onSubmitted: _searchPlace,
                  ),
                ),
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: userLocation!,
                      zoom: 15,
                    ),
                    onMapCreated: (controller) => mapController = controller,
                    markers: Set.from(_markers),
                    polygons: Set.from(_polygons),
                    onTap: _onMapTapped,
                  ),
                ),
              ],
            ),
    );
  }
}
