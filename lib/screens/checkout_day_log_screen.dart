import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snap_check/models/active_day_log_data_model.dart';
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

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      if (mounted) {
        setState(() => currentPosition = position);
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
    }
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
    final scaffold = ScaffoldMessenger.of(context);

    try {
      final tokenData = await SharedPrefHelper.getToken();
      if (tokenData == null) throw Exception('Authentication required');

      final formData = {
        "day_log_id": "${_activeDayLogDataModel?.id ?? "0"}",
        "closing_km": closingKm!,
        "note": notes ?? '',
        "closing_km_latitude": currentPosition!.latitude.toString(),
        "closing_km_longitude": currentPosition!.longitude.toString(),
      };

      final response = await BasicService().postCloseDay(
        tokenData,
        _imageFile,
        formData,
      );

      if (response?.success == true) {
        SharedPrefHelper.clearActiveDayLog();
        stopLocationService();
      
        scaffold.showSnackBar(
          const SnackBar(
            content: Text('Checkout submitted successfully!'),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.of(context).pop(true); // Return success
      } else {
        throw Exception(response?.message ?? 'Submission failed');
      }
    } catch (e) {
      debugPrint(e.toString());
      scaffold.showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Closing K.M.',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.speed),
                  suffixText: 'km',
                ),
                keyboardType: TextInputType.number,
                onChanged: (km) => closingKm = km,
                validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
                onChanged: (text) => notes = text,
              ),
              const SizedBox(height: 20),
              Text(
                'Vehicle Photo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 8),
              Text(
                '* Photo is required for checkout',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              if (currentPosition != null) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location captured: ${currentPosition!.latitude.toStringAsFixed(4)}, '
                        '${currentPosition!.longitude.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed:
                    _isSubmitting ? null : () => _submitCheckout(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          'SUBMIT CHECKOUT',
                          style: TextStyle(fontSize: 16),
                        ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
