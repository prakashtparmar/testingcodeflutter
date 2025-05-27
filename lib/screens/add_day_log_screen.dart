import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snap_check/models/party_users_data_model.dart';
import 'package:snap_check/models/post_day_log_response_model.dart';
import 'package:snap_check/models/tour_details.dart';
import 'package:snap_check/screens/live_map_screen.dart';
import 'package:snap_check/services/basic_service.dart';
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
    'Field Visit',
    'Work from home',
    'Office Visit',
  ];

  // Dropdown items
  List<TourDetails> tourPurposes = [];
  List<TourDetails> vehicleTypes = [];
  List<TourDetails> tourTypes = [];
  List<PartyUsersDataModel> parties = [];
  String? _token;

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
    final tokenData = await SharedPrefHelper.getToken();

    setState(() {
      _token = tokenData ?? "";
    });
    _fetchTourDetails();
    _getCurrentLocation();
  }

  Future<void> _fetchTourDetails() async {
    try {
      setState(() => _loadingTourDetails = true);

      final response = await _basicService.getTourDetails();
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
      }
    } catch (e) {
      debugPrint('Error fetching tour details: $e');
    } finally {
      setState(() => _loadingTourDetails = false);
    }
  }

  Future<void> _fetchPartyUsers() async {
    try {
      final response = await _basicService.getPartyUsers(_token!);
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
      setState(() => _loadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start Day Log')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
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
                            ),
                            const SizedBox(width: 12),
                            Align(
                              alignment: Alignment.topCenter,
                              child: InkWell(
                                onTap: _pickImage,
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

                        const SizedBox(height: 24),
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
      "tour_purpose": selectedPurpose!.id.toString(),
      "vehicle_type": selectedVehicle!.id.toString(),
      "tour_type": selectedTourType!.id.toString(),
      "place_visit": placeVisited!,
      "opening_km": openingKm!,
      "opening_km_latitude": currentPosition!.latitude.toString(),
      "opening_km_longitude": currentPosition!.longitude.toString(),
    };
    // If the selected purpose's name is in the list, include party_id
    if (selectedPurpose != null &&
        purposesWithParties.contains(selectedPurpose!.name)) {
      formData["party_id"] =
          selectedParty!.id.toString(); // assumes `selectedParty` is defined
    }
    PostDayLogsResponseModel? postDayLogsResponseModel = await _basicService
        .postDayLog(_token!, imageFile, formData);
    if (postDayLogsResponseModel != null &&
        postDayLogsResponseModel.success == true) {
      if (!mounted) {
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => LiveMapScreen(logId: postDayLogsResponseModel.data!.id!),
        ),
      );
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
