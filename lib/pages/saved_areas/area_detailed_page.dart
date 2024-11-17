import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AreaDetailPage extends StatefulWidget {
  final Map<String, dynamic> area;

  const AreaDetailPage({Key? key, required this.area}) : super(key: key);

  @override
  _AreaDetailPageState createState() => _AreaDetailPageState();
}

class _AreaDetailPageState extends State<AreaDetailPage> {
  Set<Polygon> _polygons = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializePolygonAndMarkers();
  }

  void _initializePolygonAndMarkers() {
    final points = widget.area['points'] as List<dynamic>;
    final color = widget.area['color'] as Color;

    final List<LatLng> latLngPoints = points
        .map((point) => LatLng(point['latitude'], point['longitude']))
        .toList()
        .cast<LatLng>();

    _polygons = {
      Polygon(
        polygonId: const PolygonId('area'),
        points: latLngPoints,
        strokeColor: Colors.black,
        strokeWidth: 3,
        fillColor: color.withOpacity(0.3),
      ),
    };

    _createCustomMarkers(latLngPoints, color).then((markers) {
      setState(() {
        _markers = markers;
      });
    });
  }

  Future<Set<Marker>> _createCustomMarkers(
      List<LatLng> points, Color color) async {
    final List<Marker> customMarkers = [];
    for (var point in points) {
      final icon = await _createColoredMarker(color);
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
    final centroid = widget.area['centroid'] as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.area['name']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mapa no interactivo
            Expanded(
              flex: 2,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(centroid['latitude'], centroid['longitude']),
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

            // Información textual
            Row(
              children: [
                const Text(
                  'Color:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: widget.area['color'],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Centroide:',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '(${centroid['latitude']}, ${centroid['longitude']})',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Puntos del Área:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: (widget.area['points'] as List<dynamic>).length,
                itemBuilder: (context, index) {
                  final point = widget.area['points'][index];
                  return ListTile(
                    title: Text(
                      'Punto ${index + 1}: (${point['latitude']}, ${point['longitude']})',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
