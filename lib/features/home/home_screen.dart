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
import '../../core/constants/app_constants.dart';
import '../../core/services/understanding/understanding_result.dart';
import '../../data/models/memory.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attentionAsync = ref.watch(attentionItemsProvider);
    final upcomingAsync = ref.watch(upcomingItemsProvider);
    final recentAsync = ref.watch(recentlyRememberedProvider);

    return Scaffold(
      backgroundColor: YaadColors.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(attentionItemsProvider);
            ref.invalidate(upcomingItemsProvider);
            ref.invalidate(recentlyRememberedProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: YaadSpacing.md, vertical: YaadSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(context),
                const SizedBox(height: YaadSpacing.lg),

                // Attention Section ("What needs my attention?")
                _buildSectionHeader('Needs your attention', Icons.notification_important_rounded),
                const SizedBox(height: YaadSpacing.sm),
                attentionAsync.when(
                  data: (items) => _buildAttentionList(context, items),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => const Text('Error loading attention items', style: YaadTypography.bodyMedium),
                ),
                const SizedBox(height: YaadSpacing.xl),

                // Upcoming Section
                _buildSectionHeader('Upcoming', Icons.calendar_month_outlined),
                const SizedBox(height: YaadSpacing.sm),
                upcomingAsync.when(
                  data: (items) => _buildUpcomingList(context, items),
                  loading: () => const SizedBox(),
                  error: (err, stack) => const SizedBox(),
                ),
                const SizedBox(height: YaadSpacing.xl),

                // Recently Remembered Section
                _buildSectionHeader('Recently remembered', Icons.history_toggle_off_rounded),
                const SizedBox(height: YaadSpacing.sm),
                recentAsync.when(
                  data: (items) => _buildRecentlyRememberedHorizontal(context, items),
                  loading: () => const SizedBox(),
                  error: (err, stack) => const SizedBox(),
                ),
                const SizedBox(height: YaadSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppConstants.appName,
                  style: YaadTypography.displayLarge.copyWith(
                    letterSpacing: -0.8,
                    color: YaadColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: YaadColors.surfaceSubtleLight,
                    borderRadius: YaadRadius.borderPill,
                    border: Border.all(color: YaadColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 12, color: YaadColors.success),
                      const SizedBox(width: 4),
                      Text(
                        AppConstants.privacyBadge,
                        style: YaadTypography.labelSmall.copyWith(
                          color: YaadColors.textSecondaryLight,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              AppConstants.tagline,
              style: YaadTypography.bodyMedium.copyWith(
                color: YaadColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        // Profile / Settings Button
        Semantics(
          label: 'Open Settings',
          button: true,
          child: GestureDetector(
            onTap: () => context.push('/settings'),
            child: Container(
              width: YaadSpacing.minTouchTarget,
              height: YaadSpacing.minTouchTarget,
              decoration: const BoxDecoration(
                color: YaadColors.primary,
                shape: BoxShape.circle,
                boxShadow: YaadShadows.subtle,
              ),
              child: const Center(
                child: Text(
                  'YA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: YaadColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: YaadTypography.titleLarge.copyWith(fontSize: 20),
        ),
      ],
    );
  }

  Widget _buildAttentionList(BuildContext context, List<Memory> items) {
    if (items.isEmpty) {
      return Container(
        padding: YaadSpacing.cardPadding,
        decoration: BoxDecoration(
          color: YaadColors.surfaceLight,
          borderRadius: YaadRadius.borderLg,
          border: Border.all(color: YaadColors.borderLight),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: YaadColors.success, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nothing requires your urgent attention right now.',
                style: YaadTypography.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: items.map((memory) {
        return Padding(
          padding: const EdgeInsets.only(bottom: YaadSpacing.sm),
          child: InkWell(
            onTap: () => context.push('/memory/${memory.id}'),
            borderRadius: YaadRadius.borderLg,
            child: Container(
              padding: YaadSpacing.cardPadding,
              decoration: BoxDecoration(
                color: YaadColors.surfaceLight,
                borderRadius: YaadRadius.borderLg,
                border: Border.all(color: YaadColors.borderLight),
                boxShadow: YaadShadows.subtle,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: memory.documentType == 'Bill'
                          ? YaadColors.attentionUrgentBg
                          : memory.documentType == 'Insurance'
                              ? YaadColors.attentionWarningBg
                              : YaadColors.accentLight,
                      borderRadius: YaadRadius.borderMd,
                    ),
                    child: Icon(
                      memory.documentType == 'Bill'
                          ? Icons.receipt_outlined
                          : memory.documentType == 'Insurance'
                              ? Icons.security_outlined
                              : Icons.medication_outlined,
                      color: memory.documentType == 'Bill'
                          ? YaadColors.attentionUrgent
                          : memory.documentType == 'Insurance'
                              ? YaadColors.attentionWarning
                              : YaadColors.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memory.title,
                          style: YaadTypography.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          memory.subtitle ?? '',
                          style: YaadTypography.bodyMedium.copyWith(
                            color: memory.documentType == 'Bill'
                                ? YaadColors.attentionUrgent
                                : memory.documentType == 'Insurance'
                                    ? YaadColors.attentionWarning
                                    : YaadColors.textSecondaryLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (memory.actionTitle != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: const BoxDecoration(
                        color: YaadColors.primary,
                        borderRadius: YaadRadius.borderMd,
                      ),
                      child: Text(
                        memory.actionTitle!,
                        style: YaadTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUpcomingList(BuildContext context, List<Memory> items) {
    return Container(
      decoration: BoxDecoration(
        color: YaadColors.surfaceLight,
        borderRadius: YaadRadius.borderLg,
        border: Border.all(color: YaadColors.borderLight),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final isLast = idx == items.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: () => context.push('/memory/${item.id}'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.circle, size: 8, color: YaadColors.accent),
                          const SizedBox(width: 12),
                          Text(
                            item.title,
                            style: YaadTypography.titleSmall,
                          ),
                        ],
                      ),
                      Text(
                        item.subtitle ?? '',
                        style: YaadTypography.labelMedium.copyWith(
                          color: YaadColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast) const Divider(height: 1, color: YaadColors.borderLight),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentlyRememberedHorizontal(BuildContext context, List<Memory> items) {
    return SizedBox(
      height: 125,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isConfirmed = item.understandingStatus == UnderstandingStatus.confirmed;
          final isRealLocal = item.categoryKey == 'unsorted' || item.imagePath != null;

          // Important field resolution for confirmed memories
          String? importantField;
          if (item.amount != null) {
            importantField = '₹${item.amount!.toStringAsFixed(0)}';
            if (item.dueDate != null) {
              importantField = '$importantField · Due ${DateFormat('d MMM').format(item.dueDate!)}';
            }
          } else if (item.dueDate != null) {
            importantField = 'Due ${DateFormat('d MMM').format(item.dueDate!)}';
          } else if (item.expiryDate != null) {
            importantField = 'Expires ${DateFormat('d MMM').format(item.expiryDate!)}';
          } else if (item.subtitle != null && item.subtitle != 'Unclassified memory') {
            importantField = item.subtitle;
          }

          return GestureDetector(
            onTap: () => context.push('/memory/${item.id}'),
            child: Container(
              width: 170,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isConfirmed
                    ? YaadColors.surfaceLight
                    : YaadColors.surfaceSubtleLight,
                borderRadius: YaadRadius.borderLg,
                border: Border.all(
                  color: isConfirmed ? YaadColors.accent : YaadColors.borderLight,
                  width: isConfirmed ? 1.2 : 1,
                ),
                boxShadow: isConfirmed ? YaadShadows.subtle : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isConfirmed ? YaadColors.accentLight : Colors.white,
                            borderRadius: YaadRadius.borderSm,
                          ),
                          child: Text(
                            isConfirmed ? item.documentType.toUpperCase() : 'NOT UNDERSTOOD',
                            style: YaadTypography.labelSmall.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isConfirmed ? YaadColors.accent : YaadColors.textMutedLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isConfirmed
                            ? Icons.verified_rounded
                            : (isRealLocal ? Icons.camera_alt_outlined : Icons.bookmark_outline),
                        size: 14,
                        color: isConfirmed ? YaadColors.success : YaadColors.textMutedLight,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isConfirmed ? item.displayTitle : 'Untitled memory',
                        style: YaadTypography.titleSmall.copyWith(
                          fontSize: 13,
                          color: isConfirmed ? YaadColors.textPrimaryLight : YaadColors.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isConfirmed
                            ? (importantField ?? item.documentType)
                            : 'Not understood yet',
                        style: YaadTypography.labelSmall.copyWith(
                          color: isConfirmed ? YaadColors.textSecondaryLight : YaadColors.textMutedLight,
                          fontSize: 11,
                          fontWeight: isConfirmed ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
