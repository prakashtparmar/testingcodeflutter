import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:snap_check/models/active_day_log_data_model.dart';
import 'package:snap_check/models/day_log_detail_data_model.dart';
import 'package:snap_check/services/basic_service.dart';
import 'package:snap_check/services/location_service.dart';
import 'package:snap_check/services/share_pref.dart';

class CheckoutDayLogScreen extends StatefulWidget {
  const CheckoutDayLogScreen({super.key});

  @override
  State<CheckoutDayLogScreen> createState() => _CheckoutDayLogScreenState();
}

class _CheckoutDayLogScreenState extends State<CheckoutDayLogScreen> {
  XFile? _imageFile;
  String? closingKm;
  String? notes;
  final _formKey = GlobalKey<FormState>();
  Position? currentPosition;
  ActiveDayLogDataModel? _activeDayLogDataModel;
  bool _isSubmitting = false;
  DayLogDetailDataModel? dayLogDetailModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _activeDayLogDataModel =
        ModalRoute.of(context)!.settings.arguments as ActiveDayLogDataModel;
  }

  Future<void> _captureImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (picked != null) {
        setState(() => _imageFile = picked);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture image: ${e.toString()}')),
      );
    }
  }

  bool _validateCheckoutForm() {
    return _formKey.currentState?.validate() == true &&
        _imageFile != null &&
        currentPosition != null;
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled. Please enable them'),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are denied'),
              duration: Duration(seconds: 5),
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied. Please enable from settings.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }
      final tokenData = await SharedPrefHelper.getToken();
      final logDetail = await BasicService().getDayLogDetail(
        tokenData!,
        _activeDayLogDataModel!.id!,
      );

      if (logDetail != null) {
        setState(() {
          _isLoading = false;
          dayLogDetailModel = logDetail.data;
        });
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          currentPosition = position;
        });
      }
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String to24HourFormat(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm:ss').format(dt);
  }

  Future<void> _submitCheckout(BuildContext context) async {
    if (!_validateCheckoutForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final tokenData = await SharedPrefHelper.getToken();

      final formData = {
        "id": "${_activeDayLogDataModel?.id ?? "0"}",
        "end_time": to24HourFormat(TimeOfDay.now()),
        "end_km": closingKm!,
        "closenote": notes ?? '',
        "end_lat": currentPosition!.latitude.toString(),
        "end_lng": currentPosition!.longitude.toString(),
      };

      final response = await BasicService().postCloseDay(
        tokenData!,
        _imageFile,
        formData,
      );

      if (response?.success == true) {
        SharedPrefHelper.clearActiveDayLog();
        final locationService = LocationService();

        bool isRunning = await locationService.isServiceRunning();
        debugPrint("Is service running before stop: $isRunning");

        // Stop tracking
        await locationService.stopTracking();
        await locationService.forceStopAllServices();
        // Dispose when done
        await locationService.dispose();

        // Verify service is stopped
        isRunning = await locationService.isServiceRunning();
        debugPrint("Is service running after stop: $isRunning");
        SnackBar(
          content: Text("Checkout submitted successfully!"),
          duration: const Duration(seconds: 5),
        );

        Navigator.pop(context, true); // Sends 'true' back to the caller
      } else {
        SnackBar(
          content: Text('Error: ${response?.message}'),
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      debugPrint("submit failed ${e.toString()}");
      SnackBar(
        content: Text('Error: ${e.toString()}'),
        duration: const Duration(seconds: 5),
      );
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    } finally {
      debugPrint("submit finally");
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildDayLogHeader() {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic info
            if (dayLogDetailModel?.startingKm != null)
              _buildDetailRow('Opening KM', dayLogDetailModel!.startingKm!),

            // Tour details
            if (dayLogDetailModel?.purpose != null)
              _buildDetailRow(
                'Purpose',
                dayLogDetailModel!.purpose?.name ?? "N/A",
              ),

            if (dayLogDetailModel?.travelMode != null)
              _buildDetailRow(
                'Travel Mode',
                dayLogDetailModel!.travelMode!.name ?? "N/A",
              ),

            if (dayLogDetailModel?.tourType != null)
              _buildDetailRow(
                'Tour Type',
                dayLogDetailModel!.tourType!.name ?? "N/A",
              ),

            // if (_activeDayLogDataModel?.partyId != null)
            //   _buildDetailRow(
            //     'Party ID',
            //     _activeDayLogDataModel!.partyId.toString(),
            //   ),
            if (dayLogDetailModel?.placeToVisit != null)
              _buildDetailRow(
                'Place to Visit',
                dayLogDetailModel!.placeToVisit!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Checkout')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDayLogHeader(),
                  const SizedBox(height: 12),
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
                                ? 'Enter Closing KM'
                                : null,
                  ),

                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                    onChanged: (val) => notes = val,
                    validator:
                        (val) =>
                            val == null || val.isEmpty ? 'Enter Notes' : null,
                  ),

                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _captureImage,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              _imageFile == null
                                  ? Colors.grey.shade300
                                  : Colors.green,
                          width: 1.5,
                        ),
                      ),
                      child:
                          _imageFile == null
                              ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to take vehicle photo',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              )
                              : Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        File(_imageFile!.path),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  if (currentPosition != null)
                    SizedBox(
                      height: 200,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            currentPosition!.latitude,
                            currentPosition!.longitude,
                          ),
                          zoom: 15,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('currentLocation'),
                            position: LatLng(
                              currentPosition!.latitude,
                              currentPosition!.longitude,
                            ),
                          ),
                        },
                        onMapCreated: (controller) {},
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: false,
                      ),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed:
                        _isSubmitting ? null : () => _submitCheckout(context),
                    child: const Text('SUBMIT CHECKOUT'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        if (_isSubmitting || _isLoading)
          Container(
            color: Colors.black.withAlpha((0.4 * 255).round()),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
