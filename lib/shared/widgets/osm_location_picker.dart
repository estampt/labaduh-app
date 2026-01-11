import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPickResult {
  const LocationPickResult({required this.latLng});
  final LatLng latLng;
}

class OSMMapLocationPicker extends StatefulWidget {
  const OSMMapLocationPicker({
    super.key,
    this.initialCenter = const LatLng(14.5995, 120.9842),
    this.initialZoom = 13,
  });

  final LatLng initialCenter;
  final double initialZoom;

  static Future<LocationPickResult?> open(
    BuildContext context, {
    LatLng initialCenter = const LatLng(14.5995, 120.9842),
    double initialZoom = 13,
  }) {
    return showModalBottomSheet<LocationPickResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: OSMMapLocationPicker(
          initialCenter: initialCenter,
          initialZoom: initialZoom,
        ),
      ),
    );
  }

  @override
  State<OSMMapLocationPicker> createState() => _OSMMapLocationPickerState();
}

class _OSMMapLocationPickerState extends State<OSMMapLocationPicker> {
  late LatLng selected = widget.initialCenter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick your location'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, LocationPickResult(latLng: selected)),
            child: const Text('Done'),
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: widget.initialCenter,
          initialZoom: widget.initialZoom,
          onTap: (_, latLng) => setState(() => selected = latLng),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.labaduh.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: selected,
                width: 48,
                height: 48,
                child: const Icon(Icons.location_pin, size: 40),
              ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _CoordPill(latLng: selected),
          ),
        ],
      ),
    );
  }
}

class _CoordPill extends StatelessWidget {
  const _CoordPill({required this.latLng});
  final LatLng latLng;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(999),
      color: Colors.black.withOpacity(0.65),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          'Selected: ${latLng.latitude.toStringAsFixed(6)}, '
          '${latLng.longitude.toStringAsFixed(6)}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
