import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/color_tokens.dart';
import '../../app/theme/radius_tokens.dart';
import '../../app/theme/shadow_tokens.dart';
import '../../app/theme/spacing_tokens.dart';
import '../../app/theme/typography_tokens.dart';
import '../../data/models/vault_category.dart';

class VaultScreen extends ConsumerWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(vaultCategoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: YaadSpacing.md, vertical: YaadSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vault Header
              Text(
                'Life Vault',
                style: (isDark ? YaadTypography.displayLargeDark : YaadTypography.displayLarge).copyWith(
                  letterSpacing: -0.5,
                  color: isDark ? YaadColors.creamText : YaadColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Organized by your real life, not file folders.',
                style: TextStyle(
                  color: isDark ? YaadColors.creamMuted : YaadColors.textSecondaryLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: YaadSpacing.lg),

              // Categories Bento Grid
              Expanded(
                child: categoriesAsync.when(
                  data: (categories) => _buildBentoGrid(context, categories, isDark),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: YaadColors.goldAccent),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      'Failed to load categories',
                      style: TextStyle(color: isDark ? YaadColors.textPrimaryDark : YaadColors.textPrimaryLight),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBentoGrid(BuildContext context, List<VaultCategory> categories, bool isDark) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final cardBg = isDark ? YaadColors.surfaceDark : YaadColors.surfaceLight;
        final border = isDark ? YaadColors.borderDark : YaadColors.borderLight;

        // Visual jewel-accented icon container
        Color iconBg;
        Color iconColor;

        switch (cat.key.toLowerCase()) {
          case 'ids':
            iconBg = isDark ? YaadColors.categoryIdsDarkBg : YaadColors.categoryIds;
            iconColor = YaadColors.categoryIdsIcon;
            break;
          case 'bills':
            iconBg = isDark ? YaadColors.categoryBillsDarkBg : YaadColors.categoryBills;
            iconColor = YaadColors.categoryBillsIcon;
            break;
          case 'vehicles':
            iconBg = isDark ? YaadColors.categoryVehiclesDarkBg : YaadColors.categoryVehicles;
            iconColor = YaadColors.categoryVehiclesIcon;
            break;
          case 'medical':
            iconBg = isDark ? YaadColors.categoryMedicalDarkBg : YaadColors.categoryMedical;
            iconColor = YaadColors.categoryMedicalIcon;
            break;
          case 'warranties':
            iconBg = isDark ? YaadColors.categoryWarrantiesDarkBg : YaadColors.categoryWarranties;
            iconColor = YaadColors.categoryWarrantiesIcon;
            break;
          case 'education':
            iconBg = isDark ? YaadColors.categoryEducationDarkBg : YaadColors.categoryEducation;
            iconColor = YaadColors.categoryEducationIcon;
            break;
          default:
            iconBg = isDark ? YaadColors.categoryUnsortedDarkBg : YaadColors.categoryUnsorted;
            iconColor = YaadColors.categoryUnsortedIcon;
        }

        return Semantics(
          label: 'Category ${cat.title}. ${cat.count} items. ${cat.description}',
          button: true,
          child: InkWell(
            onTap: () => context.push('/vault/category/${cat.key}'),
            borderRadius: YaadRadius.borderLg,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: YaadRadius.borderLg,
                border: Border.all(color: border),
                boxShadow: YaadShadows.subtle,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Category Icon + Count Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: YaadRadius.borderMd,
                        ),
                        child: Icon(
                          cat.icon,
                          size: 22,
                          color: iconColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? YaadColors.surfaceRaised : YaadColors.surfaceSubtleLight,
                          borderRadius: YaadRadius.borderPill,
                          border: Border.all(color: border),
                        ),
                        child: Text(
                          '${cat.count}',
                          style: TextStyle(
                            color: isDark ? YaadColors.goldAccent : YaadColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Bottom Info: Title and Description
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.title,
                        style: YaadTypography.titleSmallOf(context).copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cat.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? YaadColors.textSecondaryDark : YaadColors.textSecondaryLight,
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
    );
  }
}
