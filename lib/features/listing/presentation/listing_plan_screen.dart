import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/brand_gradient_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/seller_plan.dart';
import 'listing_error_messages.dart';
import 'providers/listing_plan_controller.dart';
import 'widgets/plan_breakdown.dart';
import 'widgets/plan_card.dart';
import 'widgets/sell_step_header.dart';

/// Sell step 3 of 4 (Figma Make: ListingPlanScreen): the plans from the server side by side with
/// the payment breakdown of the selected one. Choosing and paying are added by US-008.
class ListingPlanScreen extends ConsumerWidget {
  const ListingPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final plans = ref.watch(sellerPlansProvider);
    final chosen = ref.watch(selectedPlanCodeProvider);
    final selected =
        plans.maybeWhen(data: (list) => effectivePlan(list, chosen), orElse: () => null);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SellStepHeader(
            step: 2,
            title: l10n.itemChooseListingPlan,
            subtitle: l10n.planScreenSubtitle,
            onBack: () => context.canPop() ? context.pop() : context.go(RouteNames.sell),
          ),
          Expanded(
            child: plans.when(
              loading: () => const LoadingIndicator(),
              error: (error, stack) => ErrorView(
                message: listingErrorMessage(l10n, error),
                onRetry: () => ref.invalidate(sellerPlansProvider),
              ),
              data: (list) => list.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          l10n.planNoPlans,
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : _PlanList(plans: list, selected: selected!),
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.brandBorder)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                child: BrandGradientButton(
                  label: l10n.planReviewListing,
                  trailingIcon: Icons.chevron_right_rounded,
                  onPressed: selected == null ? null : () => _review(context, l10n),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _review(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.planReviewSoon)));
  }
}

class _PlanList extends ConsumerWidget {
  final List<SellerPlan> plans;
  final SellerPlan selected;

  const _PlanList({required this.plans, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        for (var i = 0; i < plans.length; i++) ...[
          PlanCard(
            plan: plans[i],
            index: i,
            selected: plans[i].code == selected.code,
            onTap: () => ref.read(selectedPlanCodeProvider.notifier).select(plans[i].code),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.sm),
        PlanBreakdown(plan: selected),
      ],
    );
  }
}
