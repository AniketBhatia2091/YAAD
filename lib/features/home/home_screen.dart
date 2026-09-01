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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: YaadColors.goldAccent,
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
                // Header & Action Bar
                _buildHeader(context),
                const SizedBox(height: YaadSpacing.lg),

                // Check if the entire vault is empty across all three queries
                _buildDashboardBody(
                  context,
                  isDark: isDark,
                  attentionAsync: attentionAsync,
                  upcomingAsync: upcomingAsync,
                  recentAsync: recentAsync,
                ),
                const SizedBox(height: YaadSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardBody(
    BuildContext context, {
    required bool isDark,
    required AsyncValue<List<Memory>> attentionAsync,
    required AsyncValue<List<Memory>> upcomingAsync,
    required AsyncValue<List<Memory>> recentAsync,
  }) {
    final hasAttention = attentionAsync.valueOrNull?.isNotEmpty ?? false;
    final hasUpcoming = upcomingAsync.valueOrNull?.isNotEmpty ?? false;
    final hasRecent = recentAsync.valueOrNull?.isNotEmpty ?? false;

    // If all three categories are loaded and genuinely empty, render the premium empty state
    if (attentionAsync.hasValue &&
        upcomingAsync.hasValue &&
        recentAsync.hasValue &&
        !hasAttention &&
        !hasUpcoming &&
        !hasRecent) {
      return _buildEmptyVaultState(context, isDark);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Priority 1: Attention Items ("What needs my attention?")
        _buildSectionHeader(context, 'Needs your attention', Icons.notification_important_rounded, isUrgent: true),
        const SizedBox(height: YaadSpacing.sm),
        attentionAsync.when(
          data: (items) => _buildAttentionList(context, items, isDark),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: YaadColors.goldAccent),
            ),
          ),
          error: (err, stack) => _buildErrorCard(context, 'Couldn\'t load attention items right now.'),
        ),
        const SizedBox(height: YaadSpacing.xl),

        // Priority 2: Upcoming Deadlines
        _buildSectionHeader(context, 'Upcoming deadlines', Icons.calendar_month_outlined),
        const SizedBox(height: YaadSpacing.sm),
        upcomingAsync.when(
          data: (items) => _buildUpcomingList(context, items, isDark),
          loading: () => const SizedBox(),
          error: (err, stack) => _buildErrorCard(context, 'Couldn\'t load upcoming items.'),
        ),
        const SizedBox(height: YaadSpacing.xl),

        // Priority 3: Recently Remembered
        _buildSectionHeader(context, 'Recently remembered', Icons.history_toggle_off_rounded),
        const SizedBox(height: YaadSpacing.sm),
        recentAsync.when(
          data: (items) => _buildRecentlyRememberedHorizontal(context, items, isDark),
          loading: () => const SizedBox(),
          error: (err, stack) => _buildErrorCard(context, 'Couldn\'t load recent memories.'),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    AppConstants.appName,
                    style: (isDark ? YaadTypography.displayLargeDark : YaadTypography.displayLarge).copyWith(
                      letterSpacing: -0.8,
                      color: isDark ? YaadColors.creamText : YaadColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? YaadColors.surfaceSubtleDark : YaadColors.surfaceSubtleLight,
                      borderRadius: YaadRadius.borderPill,
                      border: Border.all(color: isDark ? YaadColors.borderDark : YaadColors.borderLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, size: 12, color: YaadColors.success),
                        const SizedBox(width: 4),
                        Text(
                          'On-device vault',
                          style: TextStyle(
                            color: isDark ? YaadColors.textSecondaryDark : YaadColors.textSecondaryLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Remember what matters. Act when it matters.',
                style: TextStyle(
                  color: isDark ? YaadColors.creamMuted : YaadColors.textSecondaryLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        // Settings CTA
        Semantics(
          label: 'Open Settings',
          button: true,
          child: GestureDetector(
            onTap: () => context.push('/settings'),
            child: Container(
              width: YaadSpacing.minTouchTarget,
              height: YaadSpacing.minTouchTarget,
              decoration: BoxDecoration(
                color: isDark ? YaadColors.surfaceRaised : YaadColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? YaadColors.borderGlass : Colors.transparent),
                boxShadow: YaadShadows.subtle,
              ),
              child: Center(
                child: Text(
                  'YA',
                  style: TextStyle(
                    color: isDark ? YaadColors.goldAccent : Colors.white,
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

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, {bool isUrgent = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isUrgent
        ? YaadColors.attentionUrgent
        : (isDark ? YaadColors.goldAccent : YaadColors.primary);

    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: (isDark ? YaadTypography.titleLargeDark : YaadTypography.titleLarge).copyWith(fontSize: 19),
        ),
      ],
    );
  }

  Widget _buildAttentionList(BuildContext context, List<Memory> items, bool isDark) {
    final cardBg = isDark ? YaadColors.surfaceDark : YaadColors.surfaceLight;
    final border = isDark ? YaadColors.borderDark : YaadColors.borderLight;

    if (items.isEmpty) {
      return Container(
        padding: YaadSpacing.cardPadding,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: YaadRadius.borderLg,
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: YaadColors.success, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nothing requires your urgent attention right now.',
                style: TextStyle(
                  color: isDark ? YaadColors.textSecondaryDark : YaadColors.textSecondaryLight,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: items.map((memory) {
        final isBill = memory.documentType.toLowerCase().contains('bill');
        final isInsurance = memory.documentType.toLowerCase().contains('insurance');

        final badgeBg = isBill
            ? YaadColors.attentionUrgentBg
            : isInsurance
                ? YaadColors.attentionWarningBg
                : YaadColors.goldSurface;

        final badgeColor = isBill
            ? YaadColors.attentionUrgent
            : isInsurance
                ? YaadColors.attentionWarning
                : YaadColors.goldAccent;

        return Padding(
          padding: const EdgeInsets.only(bottom: YaadSpacing.sm),
          child: Semantics(
            label: 'Attention item: ${memory.title}. ${memory.subtitle ?? ''}',
            button: true,
            child: InkWell(
              onTap: () => context.push('/memory/${memory.id}'),
              borderRadius: YaadRadius.borderLg,
              child: Container(
                padding: YaadSpacing.cardPadding,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: YaadRadius.borderLg,
                  border: Border.all(color: border),
                  boxShadow: YaadShadows.subtle,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: YaadRadius.borderMd,
                      ),
                      child: Icon(
                        isBill
                            ? Icons.receipt_outlined
                            : isInsurance
                                ? Icons.security_outlined
                                : Icons.medication_outlined,
                        color: badgeColor,
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
                            style: YaadTypography.titleMediumOf(context),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            memory.subtitle ?? '',
                            style: TextStyle(
                              color: isBill
                                  ? YaadColors.attentionUrgent
                                  : isInsurance
                                      ? YaadColors.attentionWarning
                                      : (isDark ? YaadColors.textSecondaryDark : YaadColors.textSecondaryLight),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (memory.actionTitle != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDark ? YaadColors.goldPrimary : YaadColors.primary,
                          borderRadius: YaadRadius.borderMd,
                        ),
                        child: Text(
                          memory.actionTitle!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUpcomingList(BuildContext context, List<Memory> items, bool isDark) {
    if (items.isEmpty) {
      return const SizedBox();
    }

    final cardBg = isDark ? YaadColors.surfaceDark : YaadColors.surfaceLight;
    final border = isDark ? YaadColors.borderDark : YaadColors.borderLight;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: YaadRadius.borderLg,
        border: Border.all(color: border),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final isLast = idx == items.length - 1;

          return Column(
            children: [
              Semantics(
                label: 'Upcoming item: ${item.title}. ${item.subtitle ?? ''}',
                button: true,
                child: InkWell(
                  onTap: () => context.push('/memory/${item.id}'),
                  borderRadius: isLast
                      ? const BorderRadius.vertical(bottom: Radius.circular(YaadRadius.lg))
                      : (idx == 0
                          ? const BorderRadius.vertical(top: Radius.circular(YaadRadius.lg))
                          : BorderRadius.zero),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.circle, size: 8, color: YaadColors.goldAccent),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  item.title,
                                  style: YaadTypography.titleSmallOf(context),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.subtitle ?? '',
                          style: TextStyle(
                            color: isDark ? YaadColors.textSecondaryDark : YaadColors.textSecondaryLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast) Divider(height: 1, color: border),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentlyRememberedHorizontal(BuildContext context, List<Memory> items, bool isDark) {
    if (items.isEmpty) {
      return const SizedBox();
    }

    final cardBg = isDark ? YaadColors.surfaceDark : YaadColors.surfaceLight;
    final unconfirmedBg = isDark ? YaadColors.surfaceRaised : YaadColors.surfaceSubtleLight;

    return SizedBox(
      height: 132,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isConfirmed = item.understandingStatus == UnderstandingStatus.confirmed;
          final isRealLocal = item.categoryKey == 'unsorted' || item.imagePath != null;

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

          final borderColor = isConfirmed
              ? YaadColors.goldAccent.withValues(alpha: 0.6)
              : (isDark ? YaadColors.borderDark : YaadColors.borderLight);

          return Semantics(
            label: 'Memory card: ${isConfirmed ? item.displayTitle : 'Untitled memory'}. ${isConfirmed ? (importantField ?? item.documentType) : 'Not understood yet'}',
            button: true,
            child: GestureDetector(
              onTap: () => context.push('/memory/${item.id}'),
              child: Container(
                width: 175,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isConfirmed ? cardBg : unconfirmedBg,
                  borderRadius: YaadRadius.borderLg,
                  border: Border.all(color: borderColor, width: isConfirmed ? 1.2 : 1),
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
                              color: isConfirmed ? YaadColors.goldSurface : (isDark ? Colors.white10 : Colors.white),
                              borderRadius: YaadRadius.borderSm,
                            ),
                            child: Text(
                              isConfirmed ? item.documentType.toUpperCase() : 'NOT UNDERSTOOD',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isConfirmed ? YaadColors.goldAccent : (isDark ? YaadColors.textMutedDark : YaadColors.textMutedLight),
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
                          color: isConfirmed ? YaadColors.success : (isDark ? YaadColors.textMutedDark : YaadColors.textMutedLight),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isConfirmed ? item.displayTitle : 'Untitled memory',
                          style: YaadTypography.titleSmallOf(context).copyWith(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isConfirmed ? (importantField ?? item.documentType) : 'Not understood yet',
                          style: TextStyle(
                            color: isConfirmed
                                ? (isDark ? YaadColors.textSecondaryDark : YaadColors.textSecondaryLight)
                                : (isDark ? YaadColors.textMutedDark : YaadColors.textMutedLight),
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyVaultState(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: isDark ? YaadColors.surfaceDark : YaadColors.surfaceLight,
        borderRadius: YaadRadius.borderXl,
        border: Border.all(color: isDark ? YaadColors.borderGlass : YaadColors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? YaadColors.goldSurface : YaadColors.accentLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 34,
              color: YaadColors.goldAccent,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your memory vault is empty',
            style: YaadTypography.titleLargeOf(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Capture your first document and YAAD will keep it safe.',
            style: TextStyle(
              color: isDark ? YaadColors.textSecondaryDark : YaadColors.textSecondaryLight,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/capture'),
            icon: const Icon(Icons.camera_alt_rounded, size: 20),
            label: const Text('Capture memory'),
            style: ElevatedButton.styleFrom(
              backgroundColor: YaadColors.goldPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: const RoundedRectangleBorder(borderRadius: YaadRadius.borderMd),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String message) {
    return Container(
      padding: YaadSpacing.cardPadding,
      decoration: const BoxDecoration(
        color: YaadColors.attentionUrgentBg,
        borderRadius: YaadRadius.borderLg,
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: YaadColors.attentionUrgent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: YaadColors.attentionUrgent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
