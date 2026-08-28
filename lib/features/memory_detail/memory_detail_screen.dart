import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../app/theme/color_tokens.dart';
import '../../app/theme/radius_tokens.dart';
import '../../app/theme/shadow_tokens.dart';
import '../../app/theme/spacing_tokens.dart';
import '../../app/theme/typography_tokens.dart';

class MemoryDetailScreen extends ConsumerStatefulWidget {
  final String memoryId;

  const MemoryDetailScreen({
    super.key,
    required this.memoryId,
  });

  @override
  ConsumerState<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends ConsumerState<MemoryDetailScreen> {
  bool _isDeleting = false;

  Future<void> _onDeletePressed() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: YaadRadius.borderLg),
          title: const Text('Delete Memory?'),
          content: const Text(
            'This will permanently delete this memory and remove its saved image from your device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: YaadColors.attentionUrgent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      final repo = ref.read(memoryRepositoryProvider);
      await repo.deleteMemory(widget.memoryId);

      // Invalidate memory providers
      ref.invalidate(recentlyRememberedProvider);
      ref.invalidate(vaultCategoriesProvider);
      ref.invalidate(searchResultsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Memory deleted.')),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete memory: ${e.toString()}')),
        );
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final memoryAsync = ref.watch(memoryByIdProvider(widget.memoryId));

    return Scaffold(
      backgroundColor: YaadColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Memory Detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SafeArea(
        child: memoryAsync.when(
          data: (memory) {
            if (memory == null) {
              return const Center(child: Text('Memory not found.'));
            }

            final imageFile = memory.imagePath != null ? File(memory.imagePath!) : null;
            final hasValidFile = imageFile != null && imageFile.existsSync();

            return SingleChildScrollView(
              padding: YaadSpacing.pagePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Preview Container
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 320),
                    decoration: const BoxDecoration(
                      color: YaadColors.surfaceDark,
                      borderRadius: YaadRadius.borderLg,
                      boxShadow: YaadShadows.subtle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasValidFile
                        ? Image.file(
                            imageFile,
                            fit: BoxFit.contain,
                          )
                        : const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.white54),
                                  SizedBox(height: 8),
                                  Text('Demo Memory (No local image)', style: TextStyle(color: Colors.white70)),
                                ],
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: YaadSpacing.lg),

                  // Metadata Header Card
                  Container(
                    padding: YaadSpacing.cardPadding,
                    decoration: BoxDecoration(
                      color: YaadColors.surfaceLight,
                      borderRadius: YaadRadius.borderLg,
                      border: Border.all(color: YaadColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              memory.title,
                              style: YaadTypography.titleLarge,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: const BoxDecoration(
                                color: YaadColors.surfaceSubtleLight,
                                borderRadius: YaadRadius.borderPill,
                              ),
                              child: Text(
                                memory.documentType.toUpperCase(),
                                style: YaadTypography.labelSmall.copyWith(
                                  color: YaadColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 16, color: YaadColors.textMutedLight),
                            const SizedBox(width: 6),
                            Text(
                              'Saved ${DateFormat('MMM d, yyyy · h:mm a').format(memory.createdAt)}',
                              style: YaadTypography.labelSmall.copyWith(color: YaadColors.textSecondaryLight),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: YaadSpacing.md),

                  // Unclassified Notice Banner
                  Container(
                    padding: YaadSpacing.cardPadding,
                    decoration: BoxDecoration(
                      color: YaadColors.accentLight,
                      borderRadius: YaadRadius.borderLg,
                      border: Border.all(color: const Color(0x4DD97706)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_outlined, color: YaadColors.accent, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'YAAD hasn\'t understood this yet.',
                              style: YaadTypography.titleSmall.copyWith(color: YaadColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'What\'s next:\nYAAD will identify and understand this memory when the intelligence layer is connected.',
                          style: YaadTypography.bodyMedium.copyWith(
                            color: YaadColors.textSecondaryLight,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: YaadSpacing.xl),

                  // Delete Memory Button
                  SizedBox(
                    width: double.infinity,
                    height: YaadSpacing.minTouchTarget,
                    child: OutlinedButton.icon(
                      onPressed: _isDeleting ? null : _onDeletePressed,
                      icon: _isDeleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: YaadColors.attentionUrgent),
                            )
                          : const Icon(Icons.delete_outline_rounded, color: YaadColors.attentionUrgent),
                      label: Text(
                        _isDeleting ? 'Deleting...' : 'Delete memory',
                        style: const TextStyle(color: YaadColors.attentionUrgent, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: YaadColors.attentionUrgentBg, width: 1.5),
                        shape: const RoundedRectangleBorder(borderRadius: YaadRadius.borderMd),
                      ),
                    ),
                  ),
                  const SizedBox(height: YaadSpacing.xl),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Failed to load memory detail: ${err.toString()}')),
        ),
      ),
    );
  }
}
