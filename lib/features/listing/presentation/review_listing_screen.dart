import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_error.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand_gradient_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../payment/domain/payment_status.dart';
import '../../payment/presentation/payment_flow.dart';
import '../domain/plan_selection.dart';
import 'listing_error_messages.dart';
import 'providers/plan_selection_controller.dart';
import 'widgets/plan_breakdown.dart';
import 'widgets/review_item_summary.dart';
import 'widgets/review_section_title.dart';
import 'widgets/sell_step_header.dart';

/// Sell step 4 of 4 (Figma Make: Review & Publish): the item and plan summary and the pay button.
/// Paying runs the checkout; the listing moves on only when the server confirms the payment.
class ReviewListingScreen extends ConsumerStatefulWidget {
  final ReviewArgs args;

  const ReviewListingScreen({super.key, required this.args});

  @override
  ConsumerState<ReviewListingScreen> createState() => _ReviewListingScreenState();
}

class _ReviewListingScreenState extends ConsumerState<ReviewListingScreen> {
  late PlanSelection _selection = widget.args.selection;
  bool _busy = false;

  /// After a failed payment the old order is spent, so the next try asks the server for a new one.
  bool _needsNewOrder = false;

  Future<void> _pay() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (_needsNewOrder && !await _reselect()) return;
      if (!mounted) return;
      final checkout = _selection.checkout;
      if (!_selection.paymentRequired || checkout == null) {
        _submitted();
        return;
      }
      final result = await ref.read(paymentFlowProvider).start(context, checkout);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      switch (result) {
        case PaymentResult.confirmed:
          _submitted();
        case PaymentResult.pending:
          _finish(l10n.paymentConfirming);
        case PaymentResult.failed:
          _needsNewOrder = true;
          _show(l10n.paymentErrorFailed);
        case PaymentResult.cancelled:
          break;
      }
    } on ApiError catch (error) {
      if (mounted) _show(listingErrorMessage(AppLocalizations.of(context), error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Asks for a new order for the same plan; false when it could not be made (the reason is shown).
  Future<bool> _reselect() async {
    final result = await ref
        .read(planSelectionControllerProvider.notifier)
        .select(widget.args.listingId, widget.args.plan.code);
    if (!mounted) return false;
    final selection = result.selection;
    if (result.outcome != PlanSelectionOutcome.selected || selection == null) {
      final l10n = AppLocalizations.of(context);
      _show(result.outcome == PlanSelectionOutcome.aadhaarRequired
          ? l10n.homeSellAadhaarRequired
          : listingErrorMessage(l10n, result.error));
      return false;
    }
    _selection = selection;
    _needsNewOrder = false;
    return true;
  }

  /// The plan is paid (or costs nothing): the listing is with the Trust & Safety review.
  void _submitted() {
    context.go(RouteNames.sellSubmitted, extra: widget.args.listingId);
  }

  /// The payment is not confirmed yet, so the listing is not known to be paid: say so and go Home.
  void _finish(String message) {
    _show(message);
    context.go(RouteNames.home);
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final args = widget.args;
    final free = !_selection.paymentRequired;
    final selecting = ref.watch(planSelectionControllerProvider);
    return Scaffold(
      backgroundColor: AppColors.brandSurface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SellStepHeader(
              step: 3,
              title: l10n.reviewTitle,
              subtitle: l10n.reviewSubtitle,
              onBack: () => context.canPop() ? context.pop() : context.go(RouteNames.sell),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList.list(
              children: [
                ReviewItemSummary(summary: args.summary),
                const Divider(height: AppSpacing.lg * 2, color: AppColors.brandDivider),
                ReviewSectionTitle(l10n.reviewPlanSection),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset('assets/icons/review_bolt.svg',
                        width: 22, height: 22, excludeFromSemantics: true),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(args.plan.name,
                              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: AppSpacing.xs),
                          Text(l10n.reviewValidity(args.plan.validityDays),
                              style: AppTextStyles.bodySecondary),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      fit: FlexFit.tight,
                      child: Text(
                        args.plan.isFree ? l10n.planFree : Formatters.money(args.plan.totalAmount),
                        style: AppTextStyles.cardTitle,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.lg * 2, color: AppColors.brandDivider),
                PlanBreakdown(plan: args.plan, framed: false),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset('assets/icons/review_shield.svg',
                        width: 22, height: 22, excludeFromSemantics: true),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.reviewTrustTitle,
                              style: AppTextStyles.bodySecondary.copyWith(
                                color: AppColors.brandForeground,
                                fontWeight: FontWeight.w700,
                              )),
                          const SizedBox(height: AppSpacing.xs),
                          Text(l10n.reviewTrustNote, style: AppTextStyles.bodySecondary),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.brandSurface,
          border: Border(top: BorderSide(color: AppColors.brandDivider)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandGradientButton(
                  label: free
                      ? l10n.reviewPublish
                      : l10n.reviewPay(Formatters.money(_selection.amount)),
                  isLoading: _busy || selecting,
                  onPressed: _pay,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.reviewApprovalNote,
                    textAlign: TextAlign.center, style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
