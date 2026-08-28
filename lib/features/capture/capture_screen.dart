import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/providers.dart';
import '../../app/theme/color_tokens.dart';
import '../../app/theme/radius_tokens.dart';
import '../../app/theme/shadow_tokens.dart';
import '../../app/theme/typography_tokens.dart';
import '../../core/services/camera_service.dart';

/// Real device camera capture screen for YAAD "Point & Remember".
class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> with WidgetsBindingObserver {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize camera on initial load
    Future.microtask(() {
      ref.read(cameraServiceProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraService = ref.read(cameraServiceProvider.notifier);
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      cameraService.dispose();
    } else if (state == AppLifecycleState.resumed) {
      cameraService.initialize();
    }
  }

  Future<void> _onShutterTapped() async {
    final cameraService = ref.read(cameraServiceProvider.notifier);
    if (!cameraService.isInitialized || cameraService.isCapturing) return;

    final xFile = await cameraService.capturePhoto();
    if (xFile != null && mounted) {
      context.push('/preview', extra: xFile.path);
    }
  }

  Future<void> _onGalleryImportTapped() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (!mounted) return;

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final exists = await file.exists();
        if (!mounted) return;

        if (exists) {
          context.push('/preview', extra: pickedFile.path);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('We couldn\'t open that image.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('We couldn\'t open that image: ${e.toString()}')),
        );
      }
    }
  }

  IconData _getFlashIcon(FlashMode mode) {
    switch (mode) {
      case FlashMode.off:
        return Icons.flash_off_rounded;
      case FlashMode.auto:
        return Icons.flash_auto_rounded;
      case FlashMode.always:
      case FlashMode.torch:
        return Icons.flash_on_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cameraService = ref.watch(cameraServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Center Camera Preview / State Container
            Positioned.fill(
              child: _buildCameraBody(cameraService),
            ),

            // Top Control Bar (Close, Flash, Status)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    label: 'Close capture',
                    child: IconButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),

                  // Status Chip ("Ready to remember")
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: YaadRadius.borderPill,
                      border: Border.all(color: YaadColors.accent, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, size: 8, color: YaadColors.accent),
                        const SizedBox(width: 6),
                        Text(
                          'Ready to remember',
                          style: YaadTypography.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Flash Control Toggle
                  IconButton(
                    onPressed: cameraService.isInitialized
                        ? () => cameraService.toggleFlashMode()
                        : null,
                    icon: Icon(
                      _getFlashIcon(cameraService.currentFlashMode),
                      color: cameraService.currentFlashMode != FlashMode.off
                          ? YaadColors.accent
                          : Colors.white,
                      size: 24,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Action Controls
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery / Import Button
                  Semantics(
                    label: 'Import from Gallery',
                    child: IconButton(
                      onPressed: _onGalleryImportTapped,
                      icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 28),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white12,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),

                  // Prominent Large YAAD Shutter Button
                  Semantics(
                    label: 'Capture Photo',
                    button: true,
                    child: GestureDetector(
                      onTap: _onShutterTapped,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: YaadColors.accent,
                              boxShadow: YaadShadows.captureButton,
                            ),
                            child: cameraService.isCapturing
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Camera Switch Button (Front <-> Rear)
                  Semantics(
                    label: 'Switch Camera',
                    child: IconButton(
                      onPressed: cameraService.hasMultipleCameras
                          ? () => cameraService.switchCamera()
                          : null,
                      icon: Icon(
                        Icons.cameraswitch_outlined,
                        color: cameraService.hasMultipleCameras ? Colors.white : Colors.white38,
                        size: 28,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white12,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraBody(CameraService cameraService) {
    if (cameraService.isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: YaadColors.accent),
            SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (cameraService.errorMessage != null || !cameraService.isInitialized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.white38),
              const SizedBox(height: 16),
              Text(
                cameraService.errorMessage ?? 'YAAD needs camera access to remember things you show it.',
                style: YaadTypography.bodyLarge.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => cameraService.initialize(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: YaadColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Active Camera Preview + Unobtrusive Document Framing Guide
    return Stack(
      children: [
        Positioned.fill(
          child: CameraPreview(cameraService.controller!),
        ),
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white38, width: 1.5),
              borderRadius: YaadRadius.borderLg,
            ),
            child: Stack(
              children: [
                Positioned(top: 16, left: 16, child: _buildReticleCorner(0)),
                Positioned(top: 16, right: 16, child: _buildReticleCorner(1)),
                Positioned(bottom: 16, left: 16, child: _buildReticleCorner(2)),
                Positioned(bottom: 16, right: 16, child: _buildReticleCorner(3)),
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        borderRadius: YaadRadius.borderPill,
                      ),
                      child: Text(
                        'Fit the important part inside the frame',
                        style: YaadTypography.labelSmall.copyWith(color: Colors.white70),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReticleCorner(int quadrant) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: (quadrant == 0 || quadrant == 1)
              ? const BorderSide(color: YaadColors.accent, width: 3)
              : BorderSide.none,
          bottom: (quadrant == 2 || quadrant == 3)
              ? const BorderSide(color: YaadColors.accent, width: 3)
              : BorderSide.none,
          left: (quadrant == 0 || quadrant == 2)
              ? const BorderSide(color: YaadColors.accent, width: 3)
              : BorderSide.none,
          right: (quadrant == 1 || quadrant == 3)
              ? const BorderSide(color: YaadColors.accent, width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }
}
