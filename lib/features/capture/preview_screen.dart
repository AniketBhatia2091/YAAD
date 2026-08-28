import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/color_tokens.dart';
import '../../app/theme/radius_tokens.dart';
import '../../app/theme/shadow_tokens.dart';
import '../../app/theme/spacing_tokens.dart';
import '../../app/theme/typography_tokens.dart';
import '../../core/utils/uuid_generator.dart';
import '../../data/models/memory.dart';

class PreviewScreen extends ConsumerStatefulWidget {
  final String imagePath;

  const PreviewScreen({
    super.key,
    required this.imagePath,
  });

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  bool _isSaving = false;

  Future<void> _onRememberPressed() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final memoryId = UuidGenerator.generate();
      final sourceFile = File(widget.imagePath);

      if (!await sourceFile.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('We couldn\'t save this memory. File not found.')),
          );
          setState(() {
            _isSaving = false;
          });
        }
        return;
      }

      // Save to persistent application documents directory memories/<uuid>/original.jpg
      final storage = ref.read(storageServiceProvider);
      final persistentPath = await storage.saveMemoryImage(
        memoryId: memoryId,
        sourceImageFile: sourceFile,
      );

      // Create unclassified Memory
      final newMemory = Memory.createUnclassified(
        id: memoryId,
        imagePath: persistentPath,
      );

      // Save to repository
      final repo = ref.read(memoryRepositoryProvider);
      await repo.createMemory(newMemory);

      // Invalidate providers so Home, Vault, and Search reflect the new memory immediately
      ref.invalidate(recentlyRememberedProvider);
      ref.invalidate(vaultCategoriesProvider);
      ref.invalidate(searchResultsProvider);

      if (mounted) {
        // Navigate to MemoryDetailScreen
        context.go('/memory/$memoryId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('YAAD couldn\'t save this memory: ${e.toString()}')),
        );
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.imagePath);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Image Preview Container
            Positioned.fill(
              child: Center(
                child: SingleChildScrollView(
                  child: Image.file(
                    file,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image_rounded, size: 64, color: Colors.white54),
                          const SizedBox(height: 12),
                          Text(
                            'We couldn\'t open that image.',
                            style: YaadTypography.bodyLarge.copyWith(color: Colors.white70),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            // Top Header Bar
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  borderRadius: YaadRadius.borderLg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Remember this?',
                      style: YaadTypography.titleLarge.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Inspect your capture before saving to YAAD.',
                      style: YaadTypography.labelSmall.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Controls
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // Retake Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/capture');
                              }
                            },
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      label: const Text('Retake', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: YaadSpacing.md),
                        minimumSize: const Size(0, YaadSpacing.minTouchTarget),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Remember Button
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        boxShadow: YaadShadows.captureButton,
                        borderRadius: YaadRadius.borderMd,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _onRememberPressed,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.bookmark_add_rounded, color: Colors.white),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Remember',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: YaadColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: YaadSpacing.md),
                          minimumSize: const Size(0, YaadSpacing.minTouchTarget),
                        ),
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
}
