import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/color_tokens.dart';
import '../../app/theme/radius_tokens.dart';
import '../../app/theme/shadow_tokens.dart';
import '../../app/theme/typography_tokens.dart';

/// Visual shell for the future "Point & Remember" camera experience.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  bool _isFlashOn = false;
  String _detectedState = 'Bill detected'; // Demo static detection state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview Viewfinder Placeholder
            Positioned.fill(
              child: Container(
                color: const Color(0xFF0F172A),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white38, width: 1.5),
                        borderRadius: YaadRadius.borderLg,
                      ),
                      child: Stack(
                        children: [
                          // Viewfinder Reticle Corners
                          Positioned(
                            top: 16,
                            left: 16,
                            child: _buildReticleCorner(0),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: _buildReticleCorner(1),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: _buildReticleCorner(2),
                          ),
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: _buildReticleCorner(3),
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.center_focus_weak_rounded,
                                  size: 64,
                                  color: Colors.white24,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Point camera at any document, bill, or receipt',
                                  style: YaadTypography.bodyMedium.copyWith(
                                    color: Colors.white54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Top Control Bar (Close, Flash)
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
                        backgroundColor: Colors.black45,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isFlashOn = !_isFlashOn;
                          });
                        },
                        icon: Icon(
                          _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          color: _isFlashOn ? YaadColors.accent : Colors.white,
                          size: 24,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Controls Area
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Subtle Detection Chip Area
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: YaadRadius.borderPill,
                      border: Border.all(color: YaadColors.accent, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 16, color: YaadColors.accent),
                        const SizedBox(width: 8),
                        Text(
                          _detectedState,
                          style: YaadTypography.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Shutter & Side Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery/Import Control
                      Semantics(
                        label: 'Import from Gallery',
                        child: IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gallery import will be connected to storage pipeline'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 28),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white12,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),

                      // Prominent Large Shutter Button
                      Semantics(
                        label: 'Capture Document',
                        button: true,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Capture pipeline shell ready'),
                              ),
                            );
                          },
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
                                child: const Icon(
                                  Icons.camera_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Manual Entry / Switch Mode Placeholder
                      Semantics(
                        label: 'Document Type Switcher',
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _detectedState = _detectedState == 'Bill detected'
                                  ? 'Document detected'
                                  : 'Bill detected';
                            });
                          },
                          icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 28),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white12,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
