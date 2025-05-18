import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snap_check/constants/constants.dart';
import 'package:snap_check/models/day_log_detail_data_model.dart';
import 'package:snap_check/services/basic_service.dart';
import 'package:snap_check/services/share_pref.dart';

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
  List<Map<String, double>> _collectedLocations = [];
  Marker? _movingMarker;
  final Set<Marker> _markers = {};

  final _formKey = GlobalKey<FormState>();
  DayLogDetailDataModel? dayLogDetailModel;
  String? _token;
  bool _isFirstLocationCaptured = false;
  CameraPosition? _initialCameraPosition;
  BitmapDescriptor? _vehicleIcon; // Custom icon for moving vehicle marker

  // Before: Widget initialized
  @override
  void initState() {
    super.initState();
    _fetchDayLogDetail(); // Fetch detail info about the log
    _loadCustomMarker(); // Load custom vehicle icon for current location marker
    _startTracking(); // Start location tracking timer
  }
  // After: Widget initialized and tracking started

  // Before: Load custom vehicle icon marker (instead of default marker)
  void _loadCustomMarker() async {
    _vehicleIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      AppAssets.mapPin,
    );
  }
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

    // Periodic timer every 1 minute to get current position
    _locationTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      if (!mounted) return; // <-- check if still mounted
      setState(() {
        currentPosition = latLng;
        _routePoints.add(latLng);
        _collectedLocations.add({
          "lat": latLng.latitude,
          "lng": latLng.longitude,
        });

        // Before: Handle first captured location on map
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
          // After first capture, update current location marker
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
      });

      _sendLocationsToServer(); // Send batched location data to backend
    });
  }
  // After: Periodic location updates added to map and sent to server

  // Before: Send collected location points to server via API
  Future<void> _sendLocationsToServer() async {
    if (_collectedLocations.isEmpty || _token == null) return;

    final body = {"day_log_id": widget.logId, "locations": _collectedLocations};

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
  Future<void> _submitCheckout() async {
    if (_formKey.currentState?.validate() != true ||
        closingImageFile == null ||
        currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill closing KM, capture image, and wait for location.',
          ),
        ),
      );
      return;
    }

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final Map<String, String> formData = {
        "day_log_id": "\${widget.logId}",
        "closing_km": closingKm!,
      };
      final response = await BasicService().postCloseDay(
        _token!,
        closingImageFile,
        formData,
      );

      Navigator.of(context).pop(); // Hide progress dialog

      if (response!.success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checkout submitted successfully!')),
        );

        Navigator.of(context).pop(true); // Close screen returning true
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submit failed: \${response.message}')),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
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
                        ),
                        const SizedBox(width: 12),
                        Align(
                          alignment: Alignment.topCenter,
                          child: InkWell(
                            onTap: _pickClosingImage,
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitCheckout,
                        child: const Text('Submit Checkout'),
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
