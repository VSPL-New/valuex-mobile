import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/promo.dart';
import 'section_header.dart';

/// Swipeable promo cards with a heading and page dots. Shows nothing when there are no promos.
class PromoCarousel extends StatefulWidget {
  final List<Promo> promos;
  final ValueChanged<Promo> onPromoTap;
  final VoidCallback onSeeAll;

  const PromoCarousel({
    super.key,
    required this.promos,
    required this.onPromoTap,
    required this.onSeeAll,
  });

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final ScrollController _controller = ScrollController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll(double pageWidth) {
    if (pageWidth <= 0 || !_controller.hasClients) return;
    final value = (_controller.offset / pageWidth).round().clamp(0, widget.promos.length - 1);
    if (value != _index) setState(() => _index = value);
  }

  @override
  Widget build(BuildContext context) {
    final promos = widget.promos;
    if (promos.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: l10n.homePromoSection,
          actionLabel: promos.length > 1 ? l10n.homeSeeAllCount(promos.length) : null,
          onAction: widget.onSeeAll,
        ),
        // A page is as wide as the screen. Cards are at least as tall as the design and grow with
        // their content, so they are not cut off at large text sizes.
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return NotificationListener<ScrollNotification>(
              onNotification: (_) {
                _onScroll(width);
                return false;
              },
              child: SingleChildScrollView(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                physics: const PageScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final promo in promos)
                      SizedBox(
                        width: width,
                        child: PromoCard(
                          promo: promo,
                          textWidth: width * 0.58,
                          onTap: () => widget.onPromoTap(promo),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        if (promos.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label: l10n.onboardingPageOf(_index + 1, promos.length),
            excludeSemantics: true,
            child: CarouselDots(count: promos.length, index: _index),
          ),
        ],
      ],
    );
  }
}

/// A dark card with a short message and one call-to-action button.
class PromoCard extends StatelessWidget {
  final Promo promo;
  final VoidCallback onTap;

  /// Width kept for the text, so the picture stays visible beside it.
  final double textWidth;

  static const double _minHeight = 232;

  const PromoCard({
    super.key,
    required this.promo,
    required this.onTap,
    required this.textWidth,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minHeight),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.brandForeground,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Stack(
            children: [
              Positioned(
                top: -32,
                right: -32,
                child: ExcludeSemantics(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brandAccent.withValues(alpha: 0.25),
                      ),
                      child: const SizedBox(width: 176, height: 176),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: 0.15,
                    child: SvgPicture.asset(AppAssets.homePromoPattern, width: 180, height: 170),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 185,
                child: Center(
                  child: SizedBox(
                    width: 185,
                    height: 124,
                    child: AppImage(source: promo.image, cacheWidth: 560),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: textWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _UrgencyPill(label: promo.badge),
                        const SizedBox(height: AppSpacing.sm),
                        Text(promo.title, style: AppTextStyles.promoTitle),
                        const SizedBox(height: AppSpacing.xs),
                        Text(promo.body, style: AppTextStyles.onGradient),
                        const SizedBox(height: AppSpacing.sm),
                        BrandGradientButton(label: promo.ctaLabel, onPressed: onTap),
                      ],
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
}

class _UrgencyPill extends StatelessWidget {
  final String label;

  const _UrgencyPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandOnPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.brandOnPrimary.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 6,
              height: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.brandOnPrimary),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.brandOnPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
