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

class CategoryMemoriesScreen extends ConsumerWidget {
  final String categoryKey;

  const CategoryMemoriesScreen({
    super.key,
    required this.categoryKey,
  });

  String _formatCategoryTitle(String key) {
    switch (key.toLowerCase()) {
      case 'ids':
        return 'IDs & Documents';
      case 'bills':
        return 'Bills & Payments';
      case 'vehicles':
        return 'Vehicles';
      case 'medical':
        return 'Medical & Health';
      case 'warranties':
        return 'Warranties';
      case 'education':
        return 'Education & Jobs';
      case 'unsorted':
        return 'Unsorted Memories';
      default:
        return key.isEmpty ? 'Category' : '${key[0].toUpperCase()}${key.substring(1)}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allMemoriesAsync = ref.watch(allMemoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = _formatCategoryTitle(categoryKey);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: allMemoriesAsync.when(
          data: (allMemories) {
            final categoryMemories = allMemories.where((m) {
              if (categoryKey == 'unsorted') {
                return m.categoryKey == 'unsorted' || m.categoryKey.isEmpty;
              }
              return m.categoryKey.toLowerCase() == categoryKey.toLowerCase();
            }).toList();

            if (categoryMemories.isEmpty) {
              return _buildEmptyState(context, isDark);
            }

            return ListView.builder(
              padding: YaadSpacing.pagePadding,
              itemCount: categoryMemories.length,
              itemBuilder: (context, index) {
                final memory = categoryMemories[index];
                return _buildMemoryCard(context, memory, isDark);
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: YaadColors.goldAccent),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Failed to load category memories',
              style: TextStyle(color: isDark ? YaadColors.textPrimaryDark : YaadColors.textPrimaryLight),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? YaadColors.goldSurface : YaadColors.accentLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 36,
                color: YaadColors.goldAccent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nothing here yet',
              style: YaadTypography.titleLargeOf(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first document to this category and YAAD will keep it safe.',
              style: TextStyle(
                color: isDark ? YaadColors.textSecondaryDark : YaadColors.textSecondaryLight,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/capture'),
              icon: const Icon(Icons.add_a_photo_rounded, size: 20),
              label: const Text('Add a memory'),
              style: ElevatedButton.styleFrom(
                backgroundColor: YaadColors.goldPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: const RoundedRectangleBorder(borderRadius: YaadRadius.borderMd),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryCard(BuildContext context, Memory memory, bool isDark) {
    final cardBg = isDark ? YaadColors.surfaceDark : YaadColors.surfaceLight;
    final borderColor = isDark ? YaadColors.borderDark : YaadColors.borderLight;
    final isConfirmed = memory.understandingStatus == UnderstandingStatus.confirmed;

    String? displayDate;
    if (memory.dueDate != null) {
      displayDate = 'Due ${DateFormat('d MMM yyyy').format(memory.dueDate!)}';
    } else if (memory.expiryDate != null) {
      displayDate = 'Expires ${DateFormat('d MMM yyyy').format(memory.expiryDate!)}';
    } else {
      displayDate = DateFormat('d MMM yyyy').format(memory.createdAt);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: YaadSpacing.sm),
      child: Semantics(
        label: 'Memory: ${memory.displayTitle}. $displayDate',
        button: true,
        child: InkWell(
          onTap: () => context.push('/memory/${memory.id}'),
          borderRadius: YaadRadius.borderLg,
          child: Container(
            padding: YaadSpacing.cardPadding,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: YaadRadius.borderLg,
              border: Border.all(color: borderColor),
              boxShadow: YaadShadows.subtle,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? YaadColors.surfaceSubtleDark : YaadColors.surfaceSubtleLight,
                    borderRadius: YaadRadius.borderMd,
                  ),
                  child: Icon(
                    isConfirmed ? Icons.description_outlined : Icons.camera_alt_outlined,
                    color: isDark ? YaadColors.goldAccent : YaadColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isConfirmed ? memory.displayTitle : (memory.title.isNotEmpty ? memory.title : 'Untitled memory'),
                        style: YaadTypography.titleSmallOf(context),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        displayDate,
                        style: TextStyle(
                          color: isDark ? YaadColors.textSecondaryDark : YaadColors.textSecondaryLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (memory.amount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: const BoxDecoration(
                      color: YaadColors.goldSurface,
                      borderRadius: YaadRadius.borderSm,
                    ),
                    child: Text(
                      '₹${memory.amount!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: YaadColors.goldAccent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? YaadColors.textMutedDark : YaadColors.textMutedLight,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
