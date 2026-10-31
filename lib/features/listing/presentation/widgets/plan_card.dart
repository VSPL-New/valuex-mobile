import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/seller_plan.dart';

/// Icon and colour for a plan card by its position in the list (Figma Make: star, bolt, crown);
/// further plans repeat the set. Never chosen by plan code.
class _PlanLook {
  final IconData icon;
  final Color accent;

  /// Selected card glow, as in Figma Make (a different strength for each plan).
  final Color glow;

  const _PlanLook(this.icon, this.accent, this.glow);

  static const List<_PlanLook> all = [
    _PlanLook(Icons.star_outline_rounded, AppColors.brandMutedText, AppColors.sellPlanGlowBasic),
    _PlanLook(Icons.bolt_rounded, AppColors.brandAccent, AppColors.sellPlanGlowBoosted),
    _PlanLook(
      Icons.workspace_premium_outlined,
      AppColors.brandPrimary,
      AppColors.sellPlanGlowPriority,
    ),
  ];
}

/// One plan: name, badge, price with the original struck through, its feature lines and a
/// "Selected" mark. Exposed to screen readers as one radio button.
class PlanCard extends StatelessWidget {
  final SellerPlan plan;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  const PlanCard({
    super.key,
    required this.plan,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final look = _PlanLook.all[index % _PlanLook.all.length];
    final radius = BorderRadius.circular(AppRadius.xl);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      onTap: onTap,
      child: MergeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: AppColors.brandSurface,
            border: Border.all(
              color: selected ? look.accent : AppColors.brandControlBorder,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              if (selected)
                BoxShadow(color: look.glow, blurRadius: 20)
              else
                const BoxShadow(color: Color(0x14135CFF), blurRadius: 10, offset: Offset(0, 2)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              splashFactory: NoSplash.splashFactory,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(plan: plan, look: look, selected: selected, l10n: l10n),
                    const SizedBox(height: AppSpacing.md),
                    for (final line in _lines(l10n))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _FeatureLine(text: line, color: look.accent),
                      ),
                    if (selected) _SelectedMark(color: look.accent, label: l10n.planSelected),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The catalog features, then the support level (when it is a known one); the validity is
  /// shown under the plan name.
  List<String> _lines(AppLocalizations l10n) {
    final support = planSupportLabel(l10n, plan.supportLevel);
    return [...plan.features, if (support != null) support];
  }
}

/// "7 days" or "1 month": whole months when the validity is a multiple of 30 days.
String planValidityText(AppLocalizations l10n, int days) {
  if (days >= 30 && days % 30 == 0) return l10n.planValidityMonths(days ~/ 30);
  return l10n.planValidityDays(days);
}

/// The support line for a known support level; unknown levels show no line.
String? planSupportLabel(AppLocalizations l10n, String level) {
  return switch (level) {
    'AI_EMAIL' => l10n.planSupportAiEmail,
    'AI_EMAIL_CHAT' => l10n.planSupportAiEmailChat,
    'AI_EMAIL_CHAT_CALL' => l10n.planSupportAiEmailChatCall,
    _ => null,
  };
}

/// Localized badge text for known badge keys, otherwise the text the server sent.
String planBadgeText(AppLocalizations l10n, String badge) {
  return switch (badge) {
    'POPULAR' => l10n.planBadgePopular,
    'BEST_VALUE' => l10n.planBadgeBestValue,
    _ => badge.replaceAll('_', ' '),
  };
}

class _Header extends StatelessWidget {
  final SellerPlan plan;
  final _PlanLook look;
  final bool selected;
  final AppLocalizations l10n;

  const _Header({
    required this.plan,
    required this.look,
    required this.selected,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? look.accent : look.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: SizedBox(
            width: 40,
            height: 40,
            child: ExcludeSemantics(
              child: Icon(
                look.icon,
                size: 20,
                color: selected ? AppColors.brandOnPrimary : look.accent,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(plan.name, style: AppTextStyles.cardTitle),
                  if (plan.badge != null)
                    _Badge(text: planBadgeText(l10n, plan.badge!), color: look.accent),
                ],
              ),
              Text(
                l10n.planValidityLabel(planValidityText(l10n, plan.validityDays)),
                style: AppTextStyles.hint.copyWith(color: AppColors.brandForeground),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _Price(plan: plan, l10n: l10n),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(AppSizes.minTouchTarget)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        child: Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.brandOnPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Price extends StatelessWidget {
  final SellerPlan plan;
  final AppLocalizations l10n;

  const _Price({required this.plan, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final original = plan.originalPrice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          plan.isFree ? l10n.planFree : Formatters.money(plan.price),
          style: AppTextStyles.cardPrice.copyWith(
            color: AppColors.brandForeground,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (plan.hasDiscount && original != null)
          Semantics(
            label: l10n.planOriginalPriceSemantics(Formatters.money(original)),
            excludeSemantics: true,
            child: Text(
              Formatters.money(original),
              style: AppTextStyles.hint.copyWith(
                color: AppColors.brandForeground,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
      ],
    );
  }
}

class _FeatureLine extends StatelessWidget {
  final String text;
  final Color color;

  const _FeatureLine({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: ExcludeSemantics(child: Icon(Icons.check_rounded, size: 16, color: color)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySecondary.copyWith(color: AppColors.brandForeground),
          ),
        ),
      ],
    );
  }
}

class _SelectedMark extends StatelessWidget {
  final Color color;
  final String label;

  const _SelectedMark({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: DecoratedBox(
        decoration:
            BoxDecoration(border: Border(top: BorderSide(color: color.withValues(alpha: 0.3)))),
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: ExcludeSemantics(
                    child: Icon(Icons.check_rounded, size: 12, color: AppColors.brandOnPrimary),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: AppTextStyles.label.copyWith(color: AppColors.brandForeground)),
            ],
          ),
        ),
      ),
    );
  }
}
