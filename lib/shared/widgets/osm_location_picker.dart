import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationPickResult {
  LocationPickResult({
    required this.latLng,
    required this.addressLabel,
  });

  final LatLng latLng;
  final String addressLabel; // user-entered label (simple + reliable)
}

class OSMMapLocationPicker extends StatefulWidget {
  const OSMMapLocationPicker({
    super.key,
    this.initialCenter = const LatLng(14.5995, 120.9842), // Manila default
    this.initialZoom = 15,
    this.initialLabel,
  });

  final LatLng initialCenter;
  final double initialZoom;
  final String? initialLabel;

  static Future<LocationPickResult?> open(
    BuildContext context, {
    LatLng? initialCenter,
    String? initialLabel,
  }) {
    return showModalBottomSheet<LocationPickResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: OSMMapLocationPicker(
          initialCenter: initialCenter ?? const LatLng(14.5995, 120.9842),
          initialLabel: initialLabel,
        ),
      ),
    );
  }

  @override
  State<OSMMapLocationPicker> createState() => _OSMMapLocationPickerState();
}

class _OSMMapLocationPickerState extends State<OSMMapLocationPicker> {
  late final MapController _mapController;
  late LatLng _picked;
  late final TextEditingController _labelCtrl;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _picked = widget.initialCenter;
    _labelCtrl = TextEditingController(text: widget.initialLabel ?? '');
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _useGps() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable Location Services')),
      );
      return;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied')),
      );
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() => _picked = LatLng(pos.latitude, pos.longitude));
    _mapController.move(_picked, 17);
  }

  void _confirm() {
    final label = _labelCtrl.text.trim();
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an address label (e.g., Home, Condo Lobby, etc.)')),
      );
      return;
    }
    Navigator.of(context).pop(LocationPickResult(latLng: _picked, addressLabel: label));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick location'),
        actions: [
          TextButton(onPressed: _confirm, child: const Text('Done')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _labelCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Address label',
                      hintText: 'e.g., Home, Office, Lobby',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _useGps,
                  icon: const Icon(Icons.my_location),
                  label: const Text('GPS'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.initialCenter,
                initialZoom: widget.initialZoom,
                onTap: (tapPos, latLng) => setState(() => _picked = latLng),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.labaduh.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _picked,
                      width: 44,
                      height: 44,
                      child: const Icon(Icons.location_on, size: 44),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Lat: ${_picked.latitude.toStringAsFixed(6)}  •  Lng: ${_picked.longitude.toStringAsFixed(6)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                OutlinedButton(
                  onPressed: () => setState(() => _picked = widget.initialCenter),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
