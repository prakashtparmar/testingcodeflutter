import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snap_check/models/day_log_detail_data_model.dart';
import 'package:snap_check/services/basic_service.dart';
import 'package:snap_check/services/share_pref.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchDayLogDetail();
    _startTracking();
  }

  Future<void> _fetchDayLogDetail() async {
    final tokenData = await SharedPrefHelper.getToken();
    final logDetail = await BasicService().getDayLogDetail(
      tokenData!,
      widget.logId,
    );

    if (logDetail != null) {
      // Use the logDetail data here (e.g., setState to update UI)
      debugPrint("_fetchDayLogDetail ${logDetail.data?.toJson().toString()}");
      setState(() {
        _token = tokenData;
        dayLogDetailModel = logDetail.data;
      });
    }
  }

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

    _locationTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);

      setState(() {
        currentPosition = latLng;
        _routePoints.add(latLng);

        if (!_isFirstLocationCaptured) {
          // Add red marker at the first location
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
          // Update moving marker
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

      _sendLocationsToServer(); // send data every minute
    });
  }

  Future<void> _sendLocationsToServer() async {
    if (_collectedLocations.isEmpty || _token == null) return;

    final body = {"day_log_id": widget.logId, "locations": _collectedLocations};

    try {
      final response = await BasicService().postDayLogLocations(_token!, body);

      if (response!.success == true) {
        debugPrint("Location data sent successfully.");
        _collectedLocations.clear(); // Clear list after successful send
      } else {
        debugPrint("Failed to send location data: ${response.message}");
      }
    } catch (e) {
      debugPrint("Error sending location data: $e");
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

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
    // Show a loading indicator while submitting
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Prepare your checkout data here, including image and location info
      // Assuming BasicService().submitCheckout exists and takes token, logId, closingKm, image, current location
      final Map<String, String> formData = {
        "day_log_id": "${widget.logId}",
        "closing_km": closingKm!,
      };
      final response = await BasicService().postCloseDay(
        _token!,
        closingImageFile,
        formData,
      );

      Navigator.of(context).pop(); // Close loading dialog

      if (response!.success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checkout submitted successfully!')),
        );

        // Pass true or some data back to indicate success
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submit failed: ${response.message}')),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _pickClosingImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => closingImageFile = picked);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // disables back press unless allowed
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
              child: GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(20.5937, 78.9629),
                  zoom: 5,
                ),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Click Image'),
                          onPressed: _pickClosingImage,
                        ),
                        const SizedBox(width: 12),
                        if (closingImageFile != null)
                          const Icon(Icons.check_circle, color: Colors.green),
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
}
