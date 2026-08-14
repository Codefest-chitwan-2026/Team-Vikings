import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../models/picked_location.dart';

class MapAddressPickerScreen extends StatefulWidget {
  const MapAddressPickerScreen({
    super.key,
    this.initialLocation,
    this.selectionHint = 'Tap anywhere on the map to select pickup location.',
  });

  final LatLng? initialLocation;
  final String selectionHint;

  @override
  State<MapAddressPickerScreen> createState() => _MapAddressPickerScreenState();
}

class _MapAddressPickerScreenState extends State<MapAddressPickerScreen> {
  static const LatLng _defaultCenter = LatLng(27.7172, 85.3240); // Kathmandu Center

  final MapController _mapController = MapController();

  LatLng? _selectedLocation;
  String _currentAddress = 'Detecting address...';
  bool _isLocating = false;
  bool _isMapReady = false;
  bool _isGeocoding = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? _defaultCenter;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    if (!mounted) return;

    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
      if (_isMapReady) {
        _mapController.move(widget.initialLocation!, 16);
      }
      _fetchRealtimeAddress(widget.initialLocation!);
      return;
    }

    // Default: locate current position immediately
    await _getCurrentUserLocation();
  }

  Future<void> _getCurrentUserLocation() async {
    if (_isLocating) return;

    if (mounted) {
      setState(() {
        _isLocating = true;
      });
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _fallbackToDefaultLocation('Location service is disabled. Centered on Kathmandu.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _fallbackToDefaultLocation('Location permission not granted. Tap map to select location.');
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final LatLng userLoc = LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      setState(() {
        _selectedLocation = userLoc;
      });

      if (_isMapReady) {
        _mapController.move(userLoc, 16);
      }

      await _fetchRealtimeAddress(userLoc);
    } catch (_) {
      _fallbackToDefaultLocation('Using default area. Tap on map to set your location.');
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  void _fallbackToDefaultLocation(String reason) {
    if (!mounted) return;
    final fallback = _selectedLocation ?? _defaultCenter;
    setState(() {
      _selectedLocation = fallback;
    });
    if (_isMapReady) {
      _mapController.move(fallback, 15);
    }
    _fetchRealtimeAddress(fallback);
  }

  void _onMapTap(LatLng location) {
    if (!mounted) return;
    setState(() {
      _selectedLocation = location;
      _currentAddress = 'Fetching address...';
    });
    _fetchRealtimeAddress(location);
  }

  Future<void> _fetchRealtimeAddress(LatLng location) async {
    if (!mounted) return;
    setState(() {
      _isGeocoding = true;
    });

    String resolvedAddress = '';

    // 1. Try local geocoding plugin
    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = [
          place.street,
          place.subLocality,
          place.locality,
          place.subAdministrativeArea,
          place.administrativeArea,
          place.country,
        ]
            .where((s) => s != null && s.trim().isNotEmpty && s != 'Unnamed Road')
            .map((s) => s!.trim())
            .toSet()
            .toList();

        if (parts.isNotEmpty) {
          resolvedAddress = parts.join(', ');
        }
      }
    } catch (_) {}

    // 2. OpenStreetMap Nominatim reverse geocode HTTP endpoint
    if (resolvedAddress.isEmpty) {
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&zoom=18&addressdetails=1',
        );
        final response = await http.get(url, headers: {
          'User-Agent': 'SharePlateApp/1.0 (contact@shareplate.app)',
        }).timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['display_name'] != null) {
            final rawName = data['display_name'].toString();
            final segments = rawName.split(',').map((s) => s.trim()).take(4).toList();
            resolvedAddress = segments.join(', ');
          }
        }
      } catch (_) {}
    }

    // 3. Fast BigDataCloud Reverse Geocoding Client
    if (resolvedAddress.isEmpty) {
      try {
        final bdcUrl = Uri.parse(
          'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${location.latitude}&longitude=${location.longitude}&localityLanguage=en',
        );
        final response = await http.get(bdcUrl).timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final locality = data['locality']?.toString() ?? '';
          final city = data['city']?.toString() ?? '';
          final principalSubdiv = data['principalSubdivision']?.toString() ?? '';
          final country = data['countryName']?.toString() ?? '';

          final parts = [locality, city, principalSubdiv, country]
              .where((s) => s.trim().isNotEmpty)
              .toSet()
              .toList();

          if (parts.isNotEmpty) {
            resolvedAddress = parts.join(', ');
          }
        }
      } catch (_) {}
    }

    // 4. Dynamic coordinate & local zone resolver fallback
    if (resolvedAddress.isEmpty) {
      resolvedAddress = _getDistrictFallback(location);
    }

    if (mounted) {
      setState(() {
        _currentAddress = resolvedAddress;
        _isGeocoding = false;
      });
    }
  }

  String _getDistrictFallback(LatLng location) {
    final lat = location.latitude;
    final lng = location.longitude;

    String area = 'Location';
    if (lat >= 27.65 && lat <= 27.75 && lng >= 85.25 && lng <= 85.40) {
      if (lat >= 27.72) {
        area = 'Kathmandu North / Maharajgunj';
      } else if (lat <= 27.68) {
        area = 'Lalitpur / Patan Area';
      } else {
        area = 'Kathmandu Central / Durbar Marg';
      }
    } else if (lat >= 27.55 && lat <= 27.75 && lng >= 84.30 && lng <= 84.55) {
      area = 'Bharatpur / Narayangarh, Chitwan';
    } else if (lat >= 28.15 && lat <= 28.30 && lng >= 83.90 && lng <= 84.05) {
      area = 'Pokhara / Lakeside';
    } else {
      area = 'GPS Location';
    }

    return '$area, Nepal (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
  }

  void _confirmLocation() {
    final LatLng location = _selectedLocation ?? _defaultCenter;
    final addressToReturn = _currentAddress.isNotEmpty && _currentAddress != 'Detecting address...' && _currentAddress != 'Fetching address...'
        ? _currentAddress
        : _getDistrictFallback(location);

    Navigator.pop(
      context,
      PickedLocation(
        latitude: location.latitude,
        longitude: location.longitude,
        address: addressToReturn,
      ),
    );
  }

  void _changeZoom(double amount) {
    if (!_isMapReady) return;
    final camera = _mapController.camera;
    final double newZoom = (camera.zoom + amount).clamp(3.0, 19.0).toDouble();
    _mapController.move(camera.center, newZoom);
  }

  @override
  Widget build(BuildContext context) {
    final currentLoc = _selectedLocation ?? _defaultCenter;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentLoc,
              initialZoom: 16,
              onTap: (_, LatLng point) => _onMapTap(point),
              onMapReady: () {
                if (!mounted) return;
                setState(() => _isMapReady = true);
                if (widget.initialLocation == null) {
                  _getCurrentUserLocation();
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.shareplate.app',
                retinaMode: true,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentLoc,
                    width: 50,
                    height: 50,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFFD32F2F),
                      size: 48,
                    ),
                  ),
                ],
              ),
              const SimpleAttributionWidget(
                source: Text('© OpenStreetMap contributors © CARTO'),
              ),
            ],
          ),

          // Back Button
          Positioned(
            top: MediaQuery.paddingOf(context).top + 12,
            left: 16,
            child: Material(
              color: Colors.white,
              elevation: 3,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, size: 20, color: Colors.black87),
                tooltip: 'Back',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Map Controls (Zoom & Current Location)
          Positioned(
            right: 16,
            bottom: 210,
            child: Column(
              children: [
                _MapControlButton(
                  icon: Icons.add,
                  tooltip: 'Zoom in',
                  onPressed: _isMapReady ? () => _changeZoom(1) : null,
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: Icons.remove,
                  tooltip: 'Zoom out',
                  onPressed: _isMapReady ? () => _changeZoom(-1) : null,
                ),
                const SizedBox(height: 8),
                _MapControlButton(
                  icon: _isLocating ? Icons.hourglass_top : Icons.my_location,
                  tooltip: 'Use current location',
                  color: AppColors.primaryEmerald,
                  onPressed: _isLocating ? null : _getCurrentUserLocation,
                ),
              ],
            ),
          ),

          // Bottom Realtime Confirmation Sheet
          Positioned(
            right: 0,
            bottom: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -2)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.location_on, color: AppColors.primaryEmerald, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Marked Pickup Location',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Realtime Location Detected',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isGeocoding)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryEmerald),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentAddress,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lat: ${currentLoc.latitude.toStringAsFixed(5)}, Long: ${currentLoc.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _confirmLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryEmerald,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Confirm this location',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, size: 20, color: color ?? Colors.black87),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}