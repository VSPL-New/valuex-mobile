import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/brand_gradient_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/plan_selection.dart';
import '../domain/seller_plan.dart';
import 'listing_error_messages.dart';
import 'providers/listing_plan_controller.dart';
import 'providers/plan_selection_controller.dart';
import 'widgets/plan_breakdown.dart';
import 'widgets/plan_card.dart';
import 'widgets/sell_step_header.dart';

/// Sell step 3 of 4 (Figma Make: ListingPlanScreen): the plans from the server side by side with
/// the payment breakdown of the selected one. Review Listing starts the plan on the server (US-008)
/// and opens the review page.
class ListingPlanScreen extends ConsumerWidget {
  final PlanArgs args;

  const ListingPlanScreen({super.key, required this.args});

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
          if (ref.watch(appConfigProvider).env == AppEnv.dev) const _DevRevisionBanner(),
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
                  isLoading: ref.watch(planSelectionControllerProvider),
                  onPressed: selected == null ? null : () => _review(context, ref, selected),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _review(BuildContext context, WidgetRef ref, SellerPlan plan) async {
    final result = await ref
        .read(planSelectionControllerProvider.notifier)
        .select(args.listingId, plan.code);
    if (!context.mounted) return;
    switch (result.outcome) {
      case PlanSelectionOutcome.selected:
        unawaited(context.push(
          RouteNames.sellReview,
          extra: ReviewArgs(
            listingId: args.listingId,
            summary: args.summary,
            plan: plan,
            selection: result.selection!,
          ),
        ));
      case PlanSelectionOutcome.aadhaarRequired:
        _show(context, AppLocalizations.of(context).homeSellAadhaarRequired);
        unawaited(context.push(RouteNames.signupAadhaar));
      case PlanSelectionOutcome.failed:
        _show(context, listingErrorMessage(AppLocalizations.of(context), result.error));
    }
  }

  void _show(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Dev builds only: the plans are being redesigned by category (US-119), so what is shown here
/// is temporary.
class _DevRevisionBanner extends StatelessWidget {
  const _DevRevisionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.sellNoteTint,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Text(
        AppLocalizations.of(context).planDevBanner,
        style: AppTextStyles.hint.copyWith(color: AppColors.brandForeground),
        textAlign: TextAlign.center,
      ),
    );
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
