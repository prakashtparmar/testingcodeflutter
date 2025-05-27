import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snap_check/constants/constants.dart';
import 'package:snap_check/models/day_log_detail_data_model.dart';
import 'package:snap_check/services/basic_service.dart';
import 'package:snap_check/services/share_pref.dart';
import 'dart:io';

const double _zoomLevel = 17;
const double _tilt = 45;
const double _bearing = 0;

class LiveMapScreen extends StatefulWidget {
  final int logId;

  const LiveMapScreen({super.key, required this.logId});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  GoogleMapController? _mapController;
  final List<LatLng> _routePoints = [];
  StreamSubscription<Position>? _positionStream;
  XFile? closingImageFile;
  String? closingKm;
  LatLng? currentPosition;
  Timer? _locationTimer;
  final List<Map<String, double>> _collectedLocations = [];
  Marker? _movingMarker;
  final Set<Marker> _markers = {};

  final _formKey = GlobalKey<FormState>();
  DayLogDetailDataModel? dayLogDetailModel;
  String? _token;
  bool _isFirstLocationCaptured = false;
  bool _isTracking = false;

  CameraPosition? _initialCameraPosition;
  String? notes;

  // Before: Widget initialized
  @override
  void initState() {
    super.initState();
    debugPrint("logId ${widget.logId}");
    _fetchDayLogDetail(); // Fetch detail info about the log
    // _startTracking(); // Start location tracking timer
  }
  // After: Widget initialized and tracking started

  // After: Custom marker icon loaded

  // Before: Fetch day log detail from API using token
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
  // After: Day log detail fetched and set to state

  // Before: Start periodic location tracking and update map markers/routes
  void _startTracking() async {
    LocationPermission permission = await Geolocator.requestPermission();
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission permanently denied')),
      );
      return;
    }

    // Start listening to position updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // updates every 10 meters
      ),
    ).listen((Position position) {
      final latLng = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      // Animate the camera
      if (_mapController != null) {
        _mapController!.animateCamera(
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
      setState(() {
        currentPosition = latLng;
        _routePoints.add(latLng);
        _collectedLocations.add({
          "latitude": latLng.latitude,
          "longitude": latLng.longitude,
        });

        if (!_isFirstLocationCaptured) {
          _initialCameraPosition = CameraPosition(
            target: latLng,
            zoom: _zoomLevel,
            tilt: _tilt,
            bearing: _bearing,
          );

          _markers.add(
            Marker(
              markerId: const MarkerId('startLocation'),
              position: latLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              infoWindow: const InfoWindow(title: "Start Location"),
            ),
          );

          _isFirstLocationCaptured = true;
        } else {
          _movingMarker = Marker(
            markerId: const MarkerId('currentLocation'),
            position: latLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: const InfoWindow(title: "Current Location"),
          );

          _markers
            ..removeWhere((m) => m.markerId.value == 'currentLocation')
            ..add(_movingMarker!);
        }
        _sendLocationsToServer();
        _isTracking = true;
      });
    });
  }

  void _stopTracking() {
    _showCheckoutBottomSheet();
  }

  void _showCheckoutBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Closing K.M.',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => closingKm = val,
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? 'Enter closing KM'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        onChanged: (val) => notes = val,
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? 'Enter notes'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () async {
                          final picked = await ImagePicker().pickImage(
                            source: ImageSource.camera,
                          );
                          if (picked != null) {
                            setModalState(() => closingImageFile = picked);
                          }
                        },
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child:
                              closingImageFile == null
                                  ? const Center(
                                    child: Text('Tap to capture image'),
                                  )
                                  : Image.file(
                                    File(closingImageFile!.path),
                                    fit: BoxFit.cover,
                                  ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _submitCheckout(context),
                          child: const Text('Submit Checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // After: Periodic location updates added to map and sent to server

  // Before: Send collected location points to server via API
  Future<void> _sendLocationsToServer() async {
    if (_collectedLocations.isEmpty) {
      debugPrint("Location list is empty. Skipping send.");
      return;
    }

    if (_token == null) {
      debugPrint("Missing token or logId. Skipping send.");
      return;
    }

    if (dayLogDetailModel == null) {
      debugPrint("Missing dayLogDetailModel. Skipping send.");
      return;
    }

    final body = {
      "day_log_id": dayLogDetailModel!.id ?? 0,
      "locations": _collectedLocations,
    };

    try {
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
  // After: Location data sent or error logged

  // Before: Dispose resources on widget removal
  @override
  void dispose() {
    _positionStream?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }
  // After: Resources cleaned up

  // Before: Validate form and submit checkout (closing KM + image + location)
  Future<void> _submitCheckout(BuildContext rootContext) async {
    if (_formKey.currentState?.validate() != true ||
        closingImageFile == null ||
        currentPosition == null) {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill closing KM, capture image, and wait for location.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: rootContext,
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

      Navigator.of(rootContext).pop(); // Hide loading dialog

      if (response?.success == true) {
        _locationTimer?.cancel();
        _positionStream?.cancel();
        setState(() => _isTracking = false);

        Navigator.of(rootContext).pop(); // Close bottom sheet
        Navigator.of(context).pop(true); // Close LiveMapScreen

        ScaffoldMessenger.of(rootContext).showSnackBar(
          const SnackBar(content: Text('Checkout submitted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(rootContext).showSnackBar(
          SnackBar(content: Text('Submit failed: ${response?.message}')),
        );
      }
    } catch (e) {
      Navigator.of(rootContext).pop(); // Hide loading
      ScaffoldMessenger.of(
        rootContext,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // After: Checkout submitted or error shown

  // Before: Open camera to pick closing image
  Future<void> _pickClosingImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => closingImageFile = picked);
    }
  }
  // After: Closing image picked and state updated

  // Before: Confirm discard tracking dialog when back pressed
  Future<bool> _onBackPressed() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Discard Tracking?'),
                content: const Text(
                  'Are you sure you want to discard live tracking and exit?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Discard'),
                  ),
                ],
              ),
        ) ??
        false;
  }
  // After: User choice returned

  // Before: Build UI with Google Map and checkout form
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await _onBackPressed();
        if (shouldExit && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Live Map Tracking')),
        body: Column(
          children: [
            Expanded(
              child:
                  _initialCameraPosition == null
                      ? const Center(child: CircularProgressIndicator())
                      : GoogleMap(
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
                        onMapCreated:
                            (controller) => _mapController = controller,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                      ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isTracking ? _stopTracking : _startTracking,
                        child: Text(
                          _isTracking ? 'Stop Tracking' : 'Start Tracking',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // After: UI built with map and checkout form
}
