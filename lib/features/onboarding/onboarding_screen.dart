import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/color_tokens.dart';
import '../../app/theme/radius_tokens.dart';
import '../../app/theme/spacing_tokens.dart';
import '../../app/theme/typography_tokens.dart';
import '../../core/constants/app_constants.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingStep> _steps = const [
    _OnboardingStep(
      headline: 'Your phone remembers everything.\nYAAD remembers what matters.',
      supportingCopy:
          'Bills. IDs. Warranties. Prescriptions. Certificates. Important things shouldn\'t disappear into your gallery.',
      ctaText: 'Continue',
      icon: Icons.auto_awesome_rounded,
    ),
    _OnboardingStep(
      headline: 'No folders. No typing.',
      supportingCopy:
          'Just show YAAD something. We\'ll recognize it, remember it, and help you act on it.',
      ctaText: 'Continue',
      icon: Icons.center_focus_strong_rounded,
    ),
    _OnboardingStep(
      headline: 'Show me one thing.',
      supportingCopy: 'Your first memory takes a few seconds.',
      ctaText: 'Start with YAAD',
      icon: Icons.shield_outlined,
    ),
  ];

  void _onNextPressed() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Complete onboarding and launch into Home
      ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YaadColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: YaadSpacing.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: YaadSpacing.md),
              // Brand Logo & Tagline Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppConstants.appName,
                    style: YaadTypography.displayLarge.copyWith(
                      letterSpacing: -1.0,
                      color: YaadColors.primary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: YaadColors.surfaceSubtleLight,
                      borderRadius: YaadRadius.borderPill,
                      border: Border.all(color: YaadColors.borderLight),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 14, color: YaadColors.success),
                        const SizedBox(width: 4),
                        Text(
                          AppConstants.privacyBadge,
                          style: YaadTypography.labelSmall.copyWith(
                            color: YaadColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: YaadSpacing.xl),

              // PageView Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    final step = _steps[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: YaadColors.accentLight,
                            borderRadius: YaadRadius.borderLg,
                          ),
                          child: Icon(
                            step.icon,
                            size: 32,
                            color: YaadColors.accent,
                          ),
                        ),
                        const SizedBox(height: YaadSpacing.xl),
                        Text(
                          step.headline,
                          style: YaadTypography.displayLarge,
                        ),
                        const SizedBox(height: YaadSpacing.md),
                        Text(
                          step.supportingCopy,
                          style: YaadTypography.bodyLarge.copyWith(
                            color: YaadColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Page Indicators & CTA
              Row(
                children: List.generate(
                  _steps.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 8),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? YaadColors.primary : YaadColors.borderLight,
                      borderRadius: YaadRadius.borderPill,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: YaadSpacing.lg),

              // Primary CTA Button
              SizedBox(
                width: double.infinity,
                height: YaadSpacing.minTouchTarget,
                child: ElevatedButton(
                  onPressed: _onNextPressed,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _steps[_currentPage].ctaText,
                        style: YaadTypography.labelLarge.copyWith(color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: YaadSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingStep {
  final String headline;
  final String supportingCopy;
  final String ctaText;
  final IconData icon;

  const _OnboardingStep({
    required this.headline,
    required this.supportingCopy,
    required this.ctaText,
    required this.icon,
  });
}
