import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

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
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  void _startTracking() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) {
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        currentPosition = latLng;
        _routePoints.add(latLng);
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void _submitCheckout() {
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checkout submitted successfully!')),
    );
  }

  Future<void> _pickClosingImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => closingImageFile = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: true,
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
    );
  }
}
