import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snap_check/models/day_log_detail_data_model.dart';
import 'package:snap_check/screens/checkout_day_log_screen.dart';
import 'package:snap_check/services/basic_service.dart';
import 'package:snap_check/services/share_pref.dart';

// Constants
const double _zoomLevel = 17;
const double _tilt = 45;
const double _bearing = 0;
const Duration _locationSendInterval = Duration(seconds: 30);
const int _minLocationsForSend = 5;
const double _significantDistance = 10; // meters

class LiveMapScreen extends StatefulWidget {
  final int logId;

  const LiveMapScreen({super.key, required this.logId});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  // Map Controllers
  GoogleMapController? _mapController;
  BitmapDescriptor? _movingMarkerIcon;
  StreamSubscription<Position>? _positionStream;
  CameraPosition? _initialCameraPosition;
  Marker? _movingMarker;
  final Set<Marker> _markers = {};

  // Location Tracking
  final List<LatLng> _routePoints = [];
  final List<Map<String, double>> _collectedLocations = [];
  LatLng? currentPosition;
  DateTime _lastSendTime = DateTime.now();
  Duration _duration = Duration.zero;
  Timer? _durationTimer;

  // State
  bool _isFirstLocationCaptured = false;
  bool _isTracking = false;
  bool _isPaused = false;
  bool _permissionsGranted = false;
  bool _loadingPermissions = true;

  // Form Data
  final _formKey = GlobalKey<FormState>();
  XFile? closingImageFile;
  String? closingKm;
  String? notes;

  // Models
  DayLogDetailDataModel? dayLogDetailModel;
  String? _token;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _checkAndRequestPermissions();
    await _fetchDayLogDetail();
    _preloadMarkerIcons();
  }

  Future<void> _preloadMarkerIcons() async {
    _movingMarkerIcon = await BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueAzure,
    );
  }

  Future<void> _checkAndRequestPermissions() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationServiceError();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showPermissionError();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showPermanentPermissionError();
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      _initializeCamera(position);

      setState(() {
        _permissionsGranted = true;
        _loadingPermissions = false;
      });
    } catch (e) {
      _handlePermissionError(e);
    }
  }

  void _initializeCamera(Position position) {
    final latLng = LatLng(position.latitude, position.longitude);
    _initialCameraPosition = CameraPosition(
      target: latLng,
      zoom: _zoomLevel,
      tilt: _tilt,
      bearing: _bearing,
    );
  }

  Future<void> _fetchDayLogDetail() async {
    final tokenData = await SharedPrefHelper.getToken();
    final logDetail = await BasicService().getDayLogDetail(
      tokenData!,
      widget.logId,
    );

    if (logDetail != null) {
      setState(() {
        _token = tokenData;
        dayLogDetailModel = logDetail.data;
      });
    }
  }

  void _startTracking() {
    setState(() {
      _isTracking = true;
      _isPaused = false;
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(_handlePositionUpdate);

    _startDurationTimer();
  }

  void _handlePositionUpdate(Position position) {
    if (!mounted || _isPaused) return;

    final latLng = LatLng(position.latitude, position.longitude);

    _updateMapCamera(latLng);
    _updateRoutePoints(latLng);
    _updateMarkers(latLng);
    _collectLocationForServer(latLng);
  }

  void _updateMapCamera(LatLng latLng) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: latLng,
          zoom: _zoomLevel,
          tilt: _tilt,
          bearing: _bearing,
        ),
      ),
    );
  }

  void _updateRoutePoints(LatLng latLng) {
    setState(() {
      currentPosition = latLng;
      _routePoints.add(latLng);
      if (!_isFirstLocationCaptured) {
        _isFirstLocationCaptured = true;
      }
    });
  }

  void _updateMarkers(LatLng latLng) {
    if (_movingMarkerIcon == null) return;

    final newMarker = Marker(
      markerId: const MarkerId('currentLocation'),
      position: latLng,
      icon: _movingMarkerIcon!,
      infoWindow: const InfoWindow(title: "Current Location"),
    );

    if (_movingMarker == null ||
        _distanceBetween(_movingMarker!.position, latLng) >
            _significantDistance) {
      setState(() {
        _markers.removeWhere((m) => m.markerId.value == 'currentLocation');
        _markers.add(newMarker);
        _movingMarker = newMarker;
      });
    }
  }

  void _collectLocationForServer(LatLng latLng) {
    _collectedLocations.add({
      "latitude": latLng.latitude,
      "longitude": latLng.longitude,
    });

    if (_collectedLocations.length >= _minLocationsForSend ||
        DateTime.now().difference(_lastSendTime) >= _locationSendInterval) {
      _sendLocationsToServer();
    }
  }

  Future<void> _sendLocationsToServer() async {
    if (_collectedLocations.isEmpty ||
        _token == null ||
        dayLogDetailModel == null) {
      return;
    }

    try {
      final body = {
        "day_log_id": dayLogDetailModel!.id ?? 0,
        "locations": _collectedLocations,
      };

      final response = await BasicService().postDayLogLocations(_token!, body);

      if (response!.success == true) {
        debugPrint("Location data sent successfully.");
        _collectedLocations.clear(); // Clear after successful send
      } else {
        debugPrint("Failed to send location data: \${response.message}");
      }
    } catch (e) {
      debugPrint("Error sending location data: $e");
    }
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _duration += const Duration(seconds: 1);
      });
    });
  }

  void _pauseTracking() {
    setState(() {
      _isPaused = true;
    });
    _positionStream?.pause();
    _durationTimer?.cancel();
  }

  void _resumeTracking() {
    setState(() {
      _isPaused = false;
    });
    _positionStream?.resume();
    _startDurationTimer();
  }

  void _stopTracking() {
    _showCheckoutBottomSheet();
  }

  void _showCheckoutBottomSheet() {}

  Future<void> _submitCheckout(BuildContext context) async {
    if (!_validateCheckoutForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final navigator = Navigator.of(context);
    final scaffold = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final formData = {
        "day_log_id": "${dayLogDetailModel?.id ?? "0"}",
        "closing_km": closingKm!,
        "note": notes!,
        "closing_km_latitude": currentPosition!.latitude.toString(),
        "closing_km_longitude": currentPosition!.longitude.toString(),
      };

      final response = await BasicService().postCloseDay(
        _token!,
        closingImageFile,
        formData,
      );

      // Navigator.of(rootContext).pop(); // Hide loading dialog

      if (response?.success == true) {
        _positionStream?.cancel();
        setState(() => _isTracking = false);

        Navigator.of(context).pop(true); // Close LiveMapScreen

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checkout submitted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submit failed: ${response?.message}')),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Hide loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  bool _validateCheckoutForm() {
    return _formKey.currentState?.validate() == true &&
        closingImageFile != null &&
        currentPosition != null;
  }

  void _cleanUpTracking() {
    _positionStream?.cancel();
    _durationTimer?.cancel();
    setState(() {
      _isTracking = false;
      _isPaused = false;
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _durationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<bool> _showPausedTrackingExitConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Paused Tracking Session'),
                content: const Text(
                  'Your tracking session is paused. '
                  'Do you want to exit without saving?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('RESUME'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('EXIT'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                      _stopTracking();
                    },
                    child: const Text('SAVE & EXIT'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Future<bool> _showActiveTrackingExitConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Active Tracking Session'),
                content: const Text(
                  'You are currently tracking your route. '
                  'Exiting now will discard all unsaved data.\n\n'
                  'Do you want to stop tracking first?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('KEEP TRACKING'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('DISCARD'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                      _stopTracking();
                    },
                    child: const Text('STOP & SAVE'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  // New method to handle back press
  Future<void> _handleBackPress() async {
    if (!mounted) return;

    if (!_isTracking) {
      // No tracking active - allow immediate exit
      Navigator.of(context).pop();
      return;
    }

    if (_isPaused) {
      // Tracking is paused - show appropriate confirmation
      final exit = await _showPausedTrackingExitConfirmation();
      if (exit) Navigator.of(context).pop();
      return;
    }

    // Active tracking - show strong warning
    final exit = await _showActiveTrackingExitConfirmation();
    if (exit) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPermissions) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_permissionsGranted) {
      return const Scaffold(
        body: Center(child: Text('Location permission is required')),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackPress();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Live Map Tracking'),
          actions: [
            if (_isTracking)
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: _showTrackingInfo,
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: GoogleMap(
                initialCameraPosition: _initialCameraPosition!,
                polylines: {
                  Polyline(
                    polylineId: const PolylineId('route'),
                    color: Colors.blue,
                    width: 5,
                    points: _routePoints,
                  ),
                },
                markers: _markers,
                onMapCreated: (controller) => _mapController = controller,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
            ),
            _buildTrackingControls(),
            _buildStatsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_isTracking) _buildTrackingDuration(),
          const SizedBox(height: 8),
          _isTracking ? _buildTrackingButtons() : _buildStartButton(),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return ElevatedButton(
      onPressed: _startTracking,
      child: const Text('START TRACKING'),
    );
  }

  Widget _buildTrackingButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isPaused ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: _isPaused ? _resumeTracking : _pauseTracking,
            child: Text(_isPaused ? 'RESUME' : 'PAUSE'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: _stopTracking,
            child: const Text('STOP'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: _isTracking ? 80 : 0,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(Icons.alt_route, '${_routePoints.length} pts'),
              _buildStatItem(Icons.timer, '${_duration.inMinutes} min'),
              _buildStatItem(
                Icons.speed,
                '${_calculateDistance().toStringAsFixed(2)} km',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildTrackingDuration() {
    return Text(
      'Tracking: ${_duration.inHours}h ${_duration.inMinutes.remainder(60)}m ${_duration.inSeconds.remainder(60)}s',
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  double _calculateDistance() {
    if (_routePoints.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 1; i < _routePoints.length; i++) {
      totalDistance += _distanceBetween(_routePoints[i - 1], _routePoints[i]);
    }
    return totalDistance / 1000; // Convert to kilometers
  }

  double _distanceBetween(LatLng a, LatLng b) {
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Discard Tracking?'),
                content: const Text(
                  'You have an ongoing tracking session. Are you sure you want to exit without saving?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('CANCEL'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('DISCARD'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  void _showTrackingInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tracking Info'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Points: ${_routePoints.length}'),
                Text('Duration: ${_duration.inMinutes} minutes'),
                Text('Distance: ${_calculateDistance().toStringAsFixed(2)} km'),
                const SizedBox(height: 16),
                const Text('Tracking is active. Stop to save your route.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showLocationServiceError() {
    setState(() {
      _loadingPermissions = false;
      _permissionsGranted = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enable location services')),
    );
  }

  void _showPermissionError() {
    setState(() {
      _loadingPermissions = false;
      _permissionsGranted = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location permission is required')),
    );
  }

  void _showPermanentPermissionError() {
    setState(() {
      _loadingPermissions = false;
      _permissionsGranted = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enable location in app settings')),
    );
  }

  void _handlePermissionError(dynamic e) {
    setState(() {
      _loadingPermissions = false;
      _permissionsGranted = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
  }
}
