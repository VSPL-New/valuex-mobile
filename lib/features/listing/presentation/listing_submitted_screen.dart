import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/brand_gradient_button.dart';
import '../../../l10n/app_localizations.dart';

/// Shown once the plan is paid (or costs nothing) and the listing has gone to the Trust & Safety review.
/// It never says the listing is live: it goes live by itself when the review approves it.
class ListingSubmittedScreen extends StatelessWidget {
  final String listingId;

  const ListingSubmittedScreen({super.key, required this.listingId});

  /// The preview page is a later story; until it exists the button only says so.
  void _preview(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).submittedPreviewSoon)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go(RouteNames.home);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      const Center(child: _SuccessMark()),
                      const SizedBox(height: AppSpacing.md),
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.submittedTitle,
                          style: AppTextStyles.heading2,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const ExcludeSemantics(
                            child: Icon(Icons.schedule_outlined, color: AppColors.brandLink),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              l10n.submittedReviewStatus,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandLink,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.submittedReviewTiming,
                        style: AppTextStyles.bodySecondary,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(height: 1, color: AppColors.brandDivider),
                      const SizedBox(height: AppSpacing.lg),
                      _SubmissionDetail(
                        icon: Icons.verified_user_outlined,
                        title: l10n.submittedApprovalTitle,
                        message: l10n.submittedApprovalMessage,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _SubmissionDetail(
                        icon: Icons.notifications_none_rounded,
                        title: l10n.submittedActionTitle,
                        message: l10n.submittedActionMessage,
                      ),
                      const Spacer(),
                      const SizedBox(height: AppSpacing.lg),
                      BrandGradientButton(
                        label: l10n.submittedPreview,
                        onPressed: () => _preview(context),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: l10n.submittedHome,
                        isOutlined: true,
                        onPressed: () => context.go(RouteNames.home),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubmissionDetail extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _SubmissionDetail({required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Icon(icon, color: AppColors.brandLink)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.xs),
              Text(message, style: AppTextStyles.bodySecondary),
            ],
          ),
        ),
      ],
    );
  }
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.brandSurfaceTint,
        shape: BoxShape.circle,
      ),
      child: const ExcludeSemantics(
        child: Icon(Icons.check_rounded, size: 36, color: AppColors.brandLink),
      ),
    );
  }
}
