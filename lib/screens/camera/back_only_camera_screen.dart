import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class BackOnlyCameraScreen extends StatefulWidget {
  const BackOnlyCameraScreen({super.key});

  @override
  State<BackOnlyCameraScreen> createState() => _BackOnlyCameraScreenState();
}

class _BackOnlyCameraScreenState extends State<BackOnlyCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  CameraDescription? _backCamera;
  bool _isBusy = false;
  bool _useFallback = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera(reinitialize: true);
    }
  }

  Future<void> _initCamera({bool reinitialize = false}) async {
    try {
      setState(() {});
      final cameras = await availableCameras();
      
      // Find back camera
      _backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      
      if (reinitialize) {
        await _controller?.dispose();
      }
      
      _controller = CameraController(
        _backCamera!,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid 
            ? ImageFormatGroup.jpeg 
            : ImageFormatGroup.bgra8888,
      );
      
      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;
      
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      debugPrint('Camera initialization failed: $e');
      if (!mounted) return;
      
      // Fallback to image picker if camera fails
      _useFallback = true;
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera unavailable, using fallback: $e')),
      );
    }
  }

  Future<void> _takePicture() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    
    try {
      if (_useFallback) {
        // Use image picker as fallback
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
          imageQuality: 80,
        );
        if (picked != null && mounted) {
          Navigator.of(context).pop(picked);
        }
      } else {
        // Use camera controller
        if (_controller == null || !_controller!.value.isInitialized) return;
        final file = await _controller!.takePicture();
        if (!mounted) return;
        Navigator.of(context).pop(XFile(file.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture image: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _onSwitchPressed() {
    // Show UI but do not switch to front camera
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Front camera is restricted'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Camera'),
        elevation: 0,
      ),
      body: _useFallback 
          ? _buildFallbackUI()
          : _buildCameraUI(),
    );
  }

  Widget _buildFallbackUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.camera_alt,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          const Text(
            'Camera Unavailable',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Using fallback camera',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isBusy ? null : _takePicture,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: _isBusy
                ? const CircularProgressIndicator()
                : const Text('Take Photo'),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraUI() {
    if (_controller == null || _initializeControllerFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return _buildFallbackUI();
        }
        
        return Stack(
          children: [
            Positioned.fill(child: CameraPreview(_controller!)),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 24,
                    top: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 28),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      GestureDetector(
                        onTap: _isBusy ? null : _takePicture,
                        child: Container(
                          height: 72,
                          width: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 28),
                        onPressed: _onSwitchPressed,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}


