import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CheckoutBottomSheet extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Function(XFile) onImageCaptured;
  final Function(String) onKmChanged;
  final Function(String) onNotesChanged;
  final Function(BuildContext) onSubmit;

  const CheckoutBottomSheet({
    super.key,
    required this.formKey,
    required this.onImageCaptured,
    required this.onKmChanged,
    required this.onNotesChanged,
    required this.onSubmit,
  });

  @override
  State<CheckoutBottomSheet> createState() => _CheckoutBottomSheetState();
}

class _CheckoutBottomSheetState extends State<CheckoutBottomSheet> {
  XFile? _imageFile;

  Future<void> _captureImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _imageFile = picked);
      widget.onImageCaptured(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: widget.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Closing K.M.',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: widget.onKmChanged,
                validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: widget.onNotesChanged,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _captureImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child:
                      _imageFile == null
                          ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 40),
                              Text('Tap to capture image'),
                            ],
                          )
                          : Image.file(
                            File(_imageFile!.path),
                            fit: BoxFit.cover,
                          ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => widget.onSubmit(context),
                  child: const Text('SUBMIT CHECKOUT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
