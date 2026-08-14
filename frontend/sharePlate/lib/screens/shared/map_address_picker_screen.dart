import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_colors.dart';
import '../../models/picked_location.dart';

class MapAddressPickerScreen extends StatefulWidget {
  const MapAddressPickerScreen({
    super.key,
    this.initialLocation,
  });

  final LatLng? initialLocation;

  @override
  State<MapAddressPickerScreen> createState() =>
      _MapAddressPickerScreenState();
}

class _MapAddressPickerScreenState
    extends State<MapAddressPickerScreen> {
  static const LatLng _defaultCenter = LatLng(
    27.7172,
    85.3240,
  );

  final MapController _mapController = MapController();

  // The location selected by the user.
  LatLng? _selectedLocation;

  bool _isLocating = false;
  bool _isMapReady = false;
  bool _isGettingAddress = false;

  @override
  void initState() {
    super.initState();

    // If editing an existing location, use it.
    _selectedLocation = widget.initialLocation;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // INITIAL LOCATION
  // ----------------------------------------------------------

  Future<void> _initializeLocation() async {
    if (!mounted) return;

    // If an existing location was provided,
    // don't ask for the user's location.
    if (widget.initialLocation != null) {
      final location = widget.initialLocation!;

      if (_isMapReady) {
        _mapController.move(
          location,
          16,
        );
      }

      return;
    }

    // Otherwise try to get the user's current location.
    await _getCurrentUserLocation();
  }

  // ----------------------------------------------------------
  // GET CURRENT USER LOCATION
  // ----------------------------------------------------------

  Future<void> _getCurrentUserLocation() async {
    if (_isLocating) return;

    if (mounted) {
      setState(() {
        _isLocating = true;
      });
    }

    try {
      // Check if location services are enabled.
      final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage(
          'Location services are turned off. '
              'You can tap the map to select a location.',
        );
        return;
      }

      // Check permission.
      LocationPermission permission =
      await Geolocator.checkPermission();

      // Ask for permission.
      if (permission == LocationPermission.denied) {
        permission =
        await Geolocator.requestPermission();
      }

      // Permission denied.
      if (permission == LocationPermission.denied) {
        _showMessage(
          'Location permission was denied. '
              'Tap the map to select a location.',
        );
        return;
      }

      // Permission permanently denied.
      if (permission ==
          LocationPermission.deniedForever) {
        _showMessage(
          'Location permission is blocked. '
              'Please enable it from Settings.',
        );
        return;
      }

      // Get GPS coordinates.
      final Position position =
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final LatLng location = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      // Store latitude + longitude.
      setState(() {
        _selectedLocation = location;
      });

      // Move map to user's location.
      if (_isMapReady) {
        _mapController.move(
          location,
          16,
        );
      }
    } catch (e) {
      _showMessage(
        'Could not get your current location. '
            'Tap the map to select a location manually.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  // ----------------------------------------------------------
  // MAP TAP
  // ----------------------------------------------------------

  void _onMapTap(LatLng location) {
    if (!mounted) return;

    // This is where the latitude and longitude
    // are captured from the map.
    setState(() {
      _selectedLocation = location;
    });
  }

  // ----------------------------------------------------------
  // REVERSE GEOCODING
  // ----------------------------------------------------------

  Future<String> _getAddressFromCoordinates(
      LatLng location,
      ) async {
    try {
      final List<Placemark> placemarks =
      await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isEmpty) {
        return _coordinatesAsAddress(location);
      }

      final Placemark place = placemarks.first;

      final List<String> addressParts = [
        place.street ?? '',
        place.subLocality ?? '',
        place.locality ?? '',
        place.administrativeArea ?? '',
        place.country ?? '',
      ]
          .where(
            (value) => value.trim().isNotEmpty,
      )
          .toSet()
          .toList();

      if (addressParts.isEmpty) {
        return _coordinatesAsAddress(location);
      }

      return addressParts.join(', ');
    } catch (e) {
      // If address lookup fails, coordinates are still
      // available and can be sent to the API.
      return _coordinatesAsAddress(location);
    }
  }

  String _coordinatesAsAddress(LatLng location) {
    return '${location.latitude.toStringAsFixed(6)}, '
        '${location.longitude.toStringAsFixed(6)}';
  }

  // ----------------------------------------------------------
  // CONFIRM LOCATION
  // ----------------------------------------------------------

  Future<void> _confirmLocation() async {
    final LatLng? location = _selectedLocation;

    if (location == null) {
      _showMessage(
        'Please tap on the map to select a location.',
      );
      return;
    }

    if (_isGettingAddress) return;

    setState(() {
      _isGettingAddress = true;
    });

    try {
      // Get address from the FINAL selected coordinates.
      final String address =
      await _getAddressFromCoordinates(
        location,
      );

      if (!mounted) return;

      // Return all THREE values.
      Navigator.pop(
        context,
        PickedLocation(
          latitude: location.latitude,
          longitude: location.longitude,
          address: address,
        ),
      );
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Could not determine the address.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingAddress = false;
        });
      }
    }
  }

  // ----------------------------------------------------------
  // MAP ZOOM
  // ----------------------------------------------------------

  void _changeZoom(double amount) {
    if (!_isMapReady) return;

    final camera = _mapController.camera;

    final double newZoom =
    (camera.zoom + amount)
        .clamp(3.0, 19.0)
        .toDouble();

    _mapController.move(
      camera.center,
      newZoom,
    );
  }

  // ----------------------------------------------------------
  // SNACKBAR
  // ----------------------------------------------------------

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bool hasSelection =
        _selectedLocation != null;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,

            options: MapOptions(
              initialCenter:
              widget.initialLocation ??
                  _defaultCenter,

              initialZoom: 15,

              // ------------------------------------------------
              // USER TAPS MAP
              // ------------------------------------------------
              onTap: (_, LatLng point) {
                _onMapTap(point);
              },

              onMapReady: () {
                if (!mounted) return;

                setState(() {
                  _isMapReady = true;
                });

                // If there is no existing location,
                // request user's current location.
                if (widget.initialLocation == null) {
                  _getCurrentUserLocation();
                }
              },
            ),

            children: [
              // ------------------------------------------------
              // MAP
              // ------------------------------------------------
              TileLayer(
                urlTemplate:
                'https://{s}.basemaps.cartocdn.com/'
                    'light_all/{z}/{x}/{y}{r}.png',

                subdomains: const [
                  'a',
                  'b',
                  'c',
                  'd',
                ],

                userAgentPackageName:
                'com.shareplate.app',

                retinaMode: true,
              ),

              // ------------------------------------------------
              // SELECTED LOCATION MARKER
              // ------------------------------------------------
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 50,
                      height: 50,
                      alignment: Alignment.topCenter,

                      child: const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                    ),
                  ],
                ),

              // ------------------------------------------------
              // MAP ATTRIBUTION
              // ------------------------------------------------
              const SimpleAttributionWidget(
                source: Text(
                  '© OpenStreetMap contributors © CARTO',
                ),
              ),
            ],
          ),

          // ----------------------------------------------------
          // BACK BUTTON
          // ----------------------------------------------------

          Positioned(
            top:
            MediaQuery.paddingOf(context).top +
                12,
            left: 16,
            child: _MapControlButton(
              icon: Icons.arrow_back,
              tooltip: 'Back',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),

          // ----------------------------------------------------
          // MAP CONTROLS
          // ----------------------------------------------------

          Positioned(
            right: 16,
            bottom: 150,
            child: Column(
              children: [
                // Zoom in
                _MapControlButton(
                  icon: Icons.add,
                  tooltip: 'Zoom in',
                  onPressed: _isMapReady
                      ? () => _changeZoom(1)
                      : null,
                ),

                const SizedBox(height: 8),

                // Zoom out
                _MapControlButton(
                  icon: Icons.remove,
                  tooltip: 'Zoom out',
                  onPressed: _isMapReady
                      ? () => _changeZoom(-1)
                      : null,
                ),

                const SizedBox(height: 8),

                // Current location
                _MapControlButton(
                  icon: _isLocating
                      ? Icons.hourglass_top
                      : Icons.my_location,
                  tooltip:
                  'Use current location',
                  onPressed:
                  _isLocating ||
                      _isGettingAddress
                      ? null
                      : _getCurrentUserLocation,
                ),
              ],
            ),
          ),

          // ----------------------------------------------------
          // BOTTOM CONFIRMATION PANEL
          // ----------------------------------------------------

          Positioned(
            right: 0,
            bottom: 0,
            left: 0,
            child: _LocationConfirmationSheet(
              hasSelection: hasSelection,
              isLocating: _isLocating,
              isGettingAddress:
              _isGettingAddress,
              onConfirm:
              hasSelection &&
                  !_isLocating &&
                  !_isGettingAddress
                  ? _confirmLocation
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MAP CONTROL BUTTON
// ============================================================

class _MapControlButton
    extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shape: const CircleBorder(),

      child: IconButton(
        icon: Icon(
          icon,
          size: 20,
        ),
        tooltip: tooltip,
        color: Colors.black87,
        onPressed: onPressed,
      ),
    );
  }
}

// ============================================================
// BOTTOM CONFIRMATION SHEET
// ============================================================

class _LocationConfirmationSheet
    extends StatelessWidget {
  const _LocationConfirmationSheet({
    required this.hasSelection,
    required this.isLocating,
    required this.isGettingAddress,
    required this.onConfirm,
  });

  final bool hasSelection;
  final bool isLocating;
  final bool isGettingAddress;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        20,
      ),

      decoration: const BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
          ),
        ],
      ),

      child: SafeArea(
        top: false,

        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            const Text(
              'Select location',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Tap anywhere on the map to '
                  'select your organization\'s location.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,

              child: ElevatedButton(
                onPressed: onConfirm,

                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  AppColors.primaryEmerald,

                  disabledBackgroundColor:
                  Colors.grey.shade300,

                  foregroundColor:
                  Colors.white,

                  elevation: 0,

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                ),

                child: isGettingAddress
                    ? const SizedBox(
                  width: 22,
                  height: 22,

                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Confirm this location',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}