import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:snap_check/models/create_day_log_response_model.dart';
import 'package:snap_check/models/party_users_data_model.dart';
import 'package:snap_check/models/tour_details.dart';
import 'package:snap_check/services/basic_service.dart';
import 'package:snap_check/services/location_service.dart';
import 'package:snap_check/services/share_pref.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class StartTripScreen extends StatefulWidget {
  const StartTripScreen({super.key});

  @override
  State<StartTripScreen> createState() => _StartTripScreenState();
}

class _StartTripScreenState extends State<StartTripScreen> {
  final DateFormat displayFormat = DateFormat('d MMMM yyyy');
  final DateFormat apiFormat = DateFormat('yyyy/MM/dd');
  DateTime? _tripDate;
  TimeOfDay? _startTime;
  final BasicService _basicService = BasicService();
  final List<String> purposesWithParties = [
    'Field-Visit',
    'Work-from-home',
    'Office-Visit',
  ];

  // Dropdown items
  List<String> travelModes = ["Car", "Bike", "Walk"];
  List<TourDetails> vehicleTypes = [];
  List<TourDetails> tourTypes = [];
  List<PartyUsersDataModel> parties = [];

  String? selectedTravelMode, purpose;
  XFile? imageFile;
  Position? currentPosition;
  GoogleMapController? mapController;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location services are disabled. Please enable the services',
            ),
          ),
        );
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied, we cannot request permissions.',
            ),
          ),
        );
        return;
      }

      LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      if (mounted) {
        setState(() {
          currentPosition = position;
        });
      }
    } catch (e) {
      debugPrint('Location error: $e');
    } finally {}
  }

  Future<void> _selectDate(BuildContext context) async {
    final initialDate = _tripDate ?? DateTime.now();
    final firstDate = _tripDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );

    setState(() {
      _tripDate = picked;
    });
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final initialTime = (_startTime ?? TimeOfDay.now());
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => imageFile = picked);
    }
  }

  void _submitForm() async {
    final tokenData = await SharedPrefHelper.getToken();
    if (_formKey.currentState?.validate() != true || imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and attach image.'),
        ),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    // Base form data
    final Map<String, String> formData = {
      "trip_date": apiFormat.format(_tripDate!),
      "start_time": _startTime!.format(context),
      "start_lat": "${currentPosition!.latitude}",
      "start_lng": "${currentPosition!.longitude}",
      "travel_mode": "$selectedTravelMode",
      "purpose": "$purpose",
    };

    CreateDayLogResponseModel? postDayLogsResponseModel = await _basicService
        .postDayLog(tokenData!, imageFile, formData);
    setState(() {
      _isLoading = false;
    });
    if (postDayLogsResponseModel != null &&
        postDayLogsResponseModel.success == true) {
      if (!mounted) {
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Handle location services disabled
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Handle permissions denied
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Handle permissions permanently denied
        return;
      }
      // Initialize
      final locationService = LocationTrackingService();

      // Start tracking
      bool started = await locationService.startTracking(
        token: tokenData,
        dayLogId: postDayLogsResponseModel.data!.id.toString(),
      );

      if (started) {
        if (mounted) Navigator.of(context).pop(true); // Close LiveMapScreen
      }
    } else if (postDayLogsResponseModel != null &&
        postDayLogsResponseModel.success == false) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(postDayLogsResponseModel.message!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Start Trip')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Trip Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _tripDate != null
                              ? displayFormat.format(_tripDate!)
                              : 'Select trip date',
                          style: TextStyle(
                            color:
                                _tripDate != null
                                    ? Colors.black
                                    : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _selectTime(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Time',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _startTime != null
                              ? _startTime!.format(context)
                              : 'Select start time',
                          style: TextStyle(
                            color:
                                _tripDate != null
                                    ? Colors.black
                                    : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildDropdownField(
                      'Travel Mode',
                      travelModes,
                      selectedTravelMode,
                      (val) {
                        setState(() {
                          selectedTravelMode = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Purpose',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (val) => purpose = val,
                      validator:
                          (val) =>
                              val == null || val.isEmpty
                                  ? 'Enter purpose'
                                  : null,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                imageFile == null
                                    ? Colors.grey.shade300
                                    : Colors.green,
                            width: 1.5,
                          ),
                        ),
                        child:
                            imageFile == null
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
                                          File(imageFile!.path),
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
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
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

                    // Show Google Map preview with marker if currentPosition is not null
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
                          onMapCreated: (controller) {
                            mapController = controller;
                          },
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: false,
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Submit & Start'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withAlpha((0.4 * 255).round()),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> items,
    String? selected,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      value: selected,
      items:
          items
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e, // or e.id, based on your logic
                  child: Text(e),
                ),
              )
              .toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Select $label' : null,
    );
  }
}
