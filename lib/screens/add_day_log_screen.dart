import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snap_check/models/create_day_log_response_model.dart';
import 'package:snap_check/models/party_users_data_model.dart';
import 'package:snap_check/models/tour_details.dart';
import 'package:snap_check/services/api_exception.dart';
import 'package:snap_check/services/basic_service.dart';
import 'package:snap_check/services/location_service.dart';
import 'package:snap_check/services/share_pref.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AddDayLogScreen extends StatefulWidget {
  const AddDayLogScreen({super.key});

  @override
  State<AddDayLogScreen> createState() => _AddDayLogScreenState();
}

class _AddDayLogScreenState extends State<AddDayLogScreen> {
  final BasicService _basicService = BasicService();
  final List<String> purposesWithParties = [
    'Field-Visit',
    'Work-from-home',
    'Office-Visit',
  ];

  // Dropdown items
  List<TourDetails> tourPurposes = [];
  List<TourDetails> vehicleTypes = [];
  List<TourDetails> tourTypes = [];
  List<PartyUsersDataModel> parties = [];

  TourDetails? selectedPurpose;
  TourDetails? selectedVehicle;
  TourDetails? selectedTourType;
  PartyUsersDataModel? selectedParty;
  String? placeVisited;
  String? openingKm;
  XFile? imageFile;
  Position? currentPosition;
  GoogleMapController? mapController;
  bool _loadingTourDetails = true;
  bool _loadingParties = true;
  bool _loadingLocation = true;

  bool get _isLoading =>
      _loadingTourDetails || _loadingParties || _loadingLocation;

  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    _loadingTourDetails = true;
    _loadingParties = true;
    _loadingLocation = true;
    await _fetchTourDetails();
    _getCurrentLocation();
  }

  Future<void> _fetchTourDetails() async {
    try {
      final tokenData = await SharedPrefHelper.getToken();
      setState(() => _loadingTourDetails = true);

      final response = await _basicService.getTourDetails(tokenData!);
      if (response != null && response.data != null) {
        setState(() {
          tourPurposes = response.data!.tourPurposes!;
          vehicleTypes = response.data!.vehicleTypes!;
          tourTypes = response.data!.tourTypes!;
          parties = [];
          selectedPurpose = response.data!.tourPurposes!.first;
          selectedVehicle = response.data!.vehicleTypes!.first;
          selectedTourType = response.data!.tourTypes!.first;
        });
        _fetchPartyUsers();
      } else {
        setState(() {
          _loadingTourDetails = false;
          _loadingParties = false;
          _loadingLocation = false;
        });
      }
    } catch (e) {
      if (e is UnauthorizedException) {
        setState(() {
          _loadingTourDetails = false;
          _loadingParties = false;
          _loadingLocation = false;
        });
        SharedPrefHelper.clearUser();
        _redirectToLogin();
      } else {
        setState(() {
          _loadingTourDetails = false;
          _loadingParties = false;
          _loadingLocation = false;
        });
      }
    } finally {
      setState(() {
        _loadingTourDetails = false;
        _loadingParties = false;
        _loadingLocation = false;
      });
    }
  }

  void _redirectToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _fetchPartyUsers() async {
    try {
      final tokenData = await SharedPrefHelper.getToken();
      final response = await _basicService.getPartyUsers(tokenData!);
      if (response != null && response.data != null) {
        setState(() {
          parties = response.data!;
        });
      }
    } catch (e) {
      debugPrint('Error fetching tour details: $e');
      if (!mounted) {
        return;
      }
    } finally {
      setState(() => _loadingParties = false);
    }
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
    } finally {
      if (mounted) {
        setState(() {
          setState(() => _loadingLocation = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Check-in Day Log')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDropdownField(
                      'Tour Purpose',
                      tourPurposes,
                      selectedPurpose,
                      (val) {
                        setState(() {
                          selectedPurpose = val;
                          selectedParty = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildDropdownField(
                      'Vehicle Type',
                      vehicleTypes,
                      selectedVehicle,
                      (val) {
                        setState(() => selectedVehicle = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    _buildDropdownField(
                      'Tour Type',
                      tourTypes,
                      selectedTourType,
                      (val) {
                        setState(() => selectedTourType = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    if (selectedPurpose != null &&
                        purposesWithParties.contains(selectedPurpose!.name))
                      _buildStringDropdownField(
                        'Select Party',
                        parties,
                        selectedParty,
                        (val) {
                          setState(() => selectedParty = val);
                        },
                      ),
                    if (selectedPurpose != null &&
                        purposesWithParties.contains(selectedPurpose!.name))
                      const SizedBox(height: 12),

                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Place Visited',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => placeVisited = val,
                      validator:
                          (val) =>
                              val == null || val.isEmpty
                                  ? 'Enter place visited'
                                  : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Opening K.M.',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => openingKm = val,
                      validator:
                          (val) =>
                              val == null || val.isEmpty
                                  ? 'Enter opening KM'
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
    List<TourDetails> items,
    TourDetails? selected,
    ValueChanged<TourDetails?> onChanged,
  ) {
    return DropdownButtonFormField<TourDetails>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      value: selected,
      items:
          items
              .map(
                (e) => DropdownMenuItem<TourDetails>(
                  value: e, // or e.id, based on your logic
                  child: Text(e.name!),
                ),
              )
              .toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Select $label' : null,
    );
  }

  Widget _buildStringDropdownField(
    String label,
    List<PartyUsersDataModel> items,
    PartyUsersDataModel? selected,
    ValueChanged<PartyUsersDataModel?> onChanged,
  ) {
    return DropdownButtonFormField<PartyUsersDataModel>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      value: selected,
      items:
          items
              .map(
                (e) => DropdownMenuItem<PartyUsersDataModel>(
                  value: e, // or e.id, based on your logic
                  child: Text(e.name!),
                ),
              )
              .toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Select $label' : null,
    );
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
    // Base form data
    final Map<String, String> formData = {
      "tour_purpose": "${selectedPurpose!.id}",
      "vehicle_type": "${selectedVehicle!.id}",
      "tour_type": "${selectedTourType!.id}",
      "place_visit": placeVisited!,
      "opening_km": openingKm!,
      "opening_km_latitude": "${currentPosition!.latitude}",
      "opening_km_longitude": "${currentPosition!.longitude}",
    };
    // If the selected purpose's name is in the list, include party_id
    if (selectedPurpose != null &&
        purposesWithParties.contains(selectedPurpose!.name)) {
      formData["party_id"] =
          selectedParty!.id.toString(); // assumes `selectedParty` is defined
    }

    CreateDayLogResponseModel? postDayLogsResponseModel = await _basicService
        .postDayLog(tokenData!, imageFile, formData);
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
}
