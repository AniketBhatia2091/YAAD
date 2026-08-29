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
import '../../core/services/understanding/understanding_result.dart';
import '../../data/models/memory.dart';

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
      ref.invalidate(attentionItemsProvider);
      ref.invalidate(upcomingItemsProvider);
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
                  // Image Preview Container (Always preserved)
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
                  const SizedBox(height: YaadSpacing.md),

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
                            Expanded(
                              child: Text(
                                memory.displayTitle,
                                style: YaadTypography.titleLarge,
                              ),
                            ),
                            const SizedBox(width: 8),
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

                  // Understanding Section: Confirmed vs NeedsReview vs Unknown
                  if (memory.understandingStatus == UnderstandingStatus.confirmed &&
                      memory.structuredFields.isNotEmpty) ...[
                    _buildConfirmedUnderstandingSection(context, memory),
                  ] else if (memory.understandingStatus == UnderstandingStatus.needsReview) ...[
                    _buildNeedsReviewBanner(context, memory),
                  ] else ...[
                    _buildUnclassifiedNoticeBanner(context, memory),
                  ],

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

  /// Displays the confirmed structured fields extracted and verified by the user.
  Widget _buildConfirmedUnderstandingSection(BuildContext context, Memory memory) {
    return Container(
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
              Row(
                children: [
                  const Icon(Icons.verified_rounded, color: YaadColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'What YAAD remembers',
                    style: YaadTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  context.push('/understanding/${memory.id}');
                },
                child: const Text('Edit'),
              ),
            ],
          ),
          const Divider(height: 20),
          for (final field in memory.structuredFields)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.displayLabel,
                    style: YaadTypography.labelSmall.copyWith(
                      color: YaadColors.textMutedLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    field.value ?? 'Not specified',
                    style: YaadTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: YaadColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Displays banner when understanding was run but needs user review.
  Widget _buildNeedsReviewBanner(BuildContext context, Memory memory) {
    return Container(
      padding: YaadSpacing.cardPadding,
      decoration: BoxDecoration(
        color: YaadColors.attentionWarningBg,
        borderRadius: YaadRadius.borderLg,
        border: Border.all(color: const Color(0x4DD97706)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: YaadColors.attentionWarning, size: 22),
              const SizedBox(width: 8),
              Text(
                'Review understanding',
                style: YaadTypography.titleSmall.copyWith(color: YaadColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'YAAD found structured details on this document. Review and confirm them.',
            style: YaadTypography.bodyMedium.copyWith(
              color: YaadColors.textSecondaryLight,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              context.push('/understanding/${memory.id}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: YaadColors.accent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 38),
            ),
            child: const Text('Review understanding'),
          ),
        ],
      ),
    );
  }

  /// Displays fallback banner for unclassified / unknown understanding state.
  Widget _buildUnclassifiedNoticeBanner(BuildContext context, Memory memory) {
    return Container(
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
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              context.push('/understanding/${memory.id}');
            },
            icon: const Icon(Icons.auto_awesome_rounded, size: 16),
            label: const Text('Understand memory'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 38),
            ),
          ),
        ],
      ),
    );
  }
}
