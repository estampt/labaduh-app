import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class LocationPickResult {
  LocationPickResult({
    required this.latLng,
    required this.addressLabel,
    required this.exactAddress,
    required this.latitude,
    required this.longitude,
  });

  final LatLng latLng;
  final String addressLabel; // user-entered label (simple + reliable)

  /// Best-effort full address string from OpenStreetMap (Nominatim).
  /// This is what you usually want to store as the *exact* address.
  final String exactAddress;

  /// Full-precision coordinates (do not round/truncate when saving).
  final double latitude;
  final double longitude;
}

class OSMMapLocationPicker extends StatefulWidget {
  const OSMMapLocationPicker({
    super.key,
    this.initialCenter = const LatLng(14.5995, 120.9842), // Manila default
    this.initialZoom = 15,
    this.initialLabel,
    this.autoUseCurrentLocation = true,
  });

  final LatLng initialCenter;
  final double initialZoom;
  final String? initialLabel;

  /// If true, tries to place the pin on the user's current location on open.
  /// If permissions/services are not available, it gracefully falls back to [initialCenter].
  final bool autoUseCurrentLocation;

  static Future<LocationPickResult?> open(
    BuildContext context, {
    LatLng? initialCenter,
    String? initialLabel,
    bool autoUseCurrentLocation = true,
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
          autoUseCurrentLocation: autoUseCurrentLocation,
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

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  bool _searching = false;
  List<_NominatimPlace> _results = [];

  // Reverse geocoding
  bool _resolvingAddress = false;
  String _exactAddress = '';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _picked = widget.initialCenter;
    _labelCtrl = TextEditingController(text: widget.initialLabel ?? '');

    if (widget.autoUseCurrentLocation) {
      // Wait for first frame so map controller is ready before moving.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initToCurrentLocationIfPossible();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _labelCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _initToCurrentLocationIfPossible() async {
    // Silent attempt (no snackbars unless something breaks unexpectedly).
    try {
      final LatLng? here = await _getCurrentLatLng(silent: true);
      if (!mounted || here == null) return;
      setState(() => _picked = here);
      _mapController.move(_picked, 17);

      // Fill exact address for current location (best effort)
      await _updateExactAddressFor(_picked);
    } catch (_) {
      // ignore
    }
  }

  Future<LatLng?> _getCurrentLatLng({required bool silent}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enable Location Services')),
        );
      }
      return null;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
      }
      return null;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return LatLng(pos.latitude, pos.longitude);
  }

  Future<void> _useGps() async {
    try {
      final here = await _getCurrentLatLng(silent: false);
      if (!mounted || here == null) return;

      setState(() {
        _picked = here;
        _results = [];
      });
      _searchFocus.unfocus();
      _mapController.move(_picked, 17);

      await _updateExactAddressFor(_picked);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get current location')),
      );
    }
  }

  Future<void> _confirm() async {
    final label = _labelCtrl.text.trim();
    /*
    if (label.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter an address label (e.g., Home, Condo Lobby, etc.)',
          ),
        ),
      );
      return;
    }
    */
    // Best-effort: if exact address is still empty, try to reverse-geocode once
    // before returning.
    if (_exactAddress.trim().isEmpty) {
      await _updateExactAddressFor(_picked);
    }
    Navigator.of(context).pop(
      LocationPickResult(
        latLng: _picked,
        addressLabel: _exactAddress.trim().isEmpty ? label : _exactAddress, //label,
        exactAddress: _exactAddress.trim().isEmpty ? label : _exactAddress,
        latitude: _picked.latitude,
        longitude: _picked.longitude,
      ),
    );
  }

  Future<void> _updateExactAddressFor(LatLng latLng) async {
    setState(() => _resolvingAddress = true);

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${latLng.latitude}&lon=${latLng.longitude}'
        '&format=json&addressdetails=1',
      );

      final res = await http.get(uri, headers: const {
        'User-Agent': 'com.labaduh.app (OSM Location Picker)',
        'Accept': 'application/json',
      });

      if (!mounted) return;

      if (res.statusCode != 200) {
        setState(() {
          _exactAddress = _exactAddress; // keep whatever we already had
          _resolvingAddress = false;
        });
        return;
      }

      final decoded = jsonDecode(res.body);
      final displayName = (decoded is Map<String, dynamic>)
          ? (decoded['display_name'] ?? '').toString()
          : '';

      setState(() {
        _exactAddress = displayName;
        _resolvingAddress = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _resolvingAddress = false);
    }
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      _search(q.trim());
    });
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }

    setState(() => _searching = true);

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(q)}'
        '&format=json&addressdetails=1&limit=8',
      );

      // Nominatim policy: set a valid User-Agent identifying your app.
      final res = await http.get(uri, headers: const {
        'User-Agent': 'com.labaduh.app (OSM Location Picker)',
        'Accept': 'application/json',
      });

      if (res.statusCode != 200) {
        if (!mounted) return;
        setState(() {
          _results = [];
          _searching = false;
        });
        return;
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! List) {
        if (!mounted) return;
        setState(() {
          _results = [];
          _searching = false;
        });
        return;
      }

      final list = decoded
          .whereType<Map<String, dynamic>>()
          .map(_NominatimPlace.fromJson)
          .toList();

      if (!mounted) return;
      setState(() {
        _results = list;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _searching = false;
      });
    }
  }

  void _selectPlace(_NominatimPlace p) {
    final latLng = LatLng(p.lat, p.lon);

    setState(() {
      _picked = latLng;
      _results = [];
      _exactAddress = p.title; // already a good "exact address" from search
    });

    _searchFocus.unfocus();
    _mapController.move(_picked, 17);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick location'),
        actions: [
          IconButton(
            tooltip: 'My location',
            onPressed: _useGps,
            icon: const Icon(Icons.my_location),
          ),
          TextButton(onPressed: _confirm, child: const Text('Done')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // 🔎 Search
                TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: 'Search location',
                    hintText: 'Type a place name (e.g., Mall of Asia, Makati)',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.trim().isEmpty
                        ? (_searching
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null)
                        : IconButton(
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {
                                _results = [];
                                _searching = false;
                              });
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                /*const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: _useGps,
                      icon: const Icon(Icons.my_location),
                      label: const Text('GPS'),
                    ),
                    */
                if (_results.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(12),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final r = _results[i];
                        return ListTile(
                          dense: true,
                          title: Text(
                            r.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'Lat: ${r.lat.toStringAsFixed(5)} • Lng: ${r.lon.toStringAsFixed(5)}',
                          ),
                          onTap: () => _selectPlace(r),
                        );
                      },
                    ),
                  ),
                ], 
                
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.initialCenter,
                initialZoom: widget.initialZoom,
                onTap: (tapPos, latLng) {
                  setState(() {
                    _picked = latLng;
                    _results = [];
                  });
                  _searchFocus.unfocus();

                  // Reverse geocode the tapped point
                  _updateExactAddressFor(latLng);
                },
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        // IMPORTANT: full precision is in the result object.
                        // Here we show a readable version.
                        'Lat: ${_picked.latitude.toStringAsFixed(6)}  •  Lng: ${_picked.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _picked = widget.initialCenter;
                          _results = [];
                          _exactAddress = '';
                        });
                        _mapController.move(_picked, widget.initialZoom);
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (_resolvingAddress)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.place, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _exactAddress.isEmpty
                            ? 'Exact address: (tap map / search to fill)'
                            : _exactAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NominatimPlace {
  _NominatimPlace({
    required this.title,
    required this.lat,
    required this.lon,
  });

  final String title;
  final double lat;
  final double lon;

  factory _NominatimPlace.fromJson(Map<String, dynamic> json) {
    return _NominatimPlace(
      title: (json['display_name'] ?? '').toString(),
      lat: double.tryParse((json['lat'] ?? '').toString()) ?? 0,
      lon: double.tryParse((json['lon'] ?? '').toString()) ?? 0,
    );
  }
}
