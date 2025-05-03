import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snap_check/models/tour_details.dart';
import 'package:snap_check/screens/live_map_screen.dart';
import 'package:snap_check/services/basic_service.dart';

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
  List<String> parties = [];

  String? selectedPurpose;
  String? selectedVehicle;
  String? selectedTourType;
  String? selectedParty;
  String? placeVisited;
  String? openingKm;
  XFile? imageFile;

  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    _fetchTourDetails();
  }

  Future<void> _fetchTourDetails() async {
    try {
      final response = await _basicService.getTourDetails();
      if (response != null && response.data != null) {
        setState(() {
          tourPurposes = response.data!.tourPurposes!;
          vehicleTypes = response.data!.vehicleTypes!;
          tourTypes = response.data!.tourTypes!;
          parties = [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching tour details: $e');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load tour details')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start Day Log')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
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

                _buildDropdownField('Tour Type', tourTypes, selectedTourType, (
                  val,
                ) {
                  setState(() => selectedTourType = val);
                }),
                const SizedBox(height: 12),

                if (purposesWithParties.contains(selectedPurpose))
                  _buildStringDropdownField(
                    'Select Party',
                    parties,
                    selectedParty,
                    (val) {
                      setState(() => selectedParty = val);
                    },
                  ),
                if (purposesWithParties.contains(selectedPurpose))
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
                          height: 56,
                          width: 56,
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
                    const SizedBox(width: 8),
                    if (imageFile != null)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),

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
                  value: e.name, // or e.id, based on your logic
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => imageFile = picked);
    }
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() != true || imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and attach image.'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LiveMapScreen()),
    );
  }
}
