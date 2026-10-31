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
                      const SizedBox(height: AppSpacing.lg),
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.submittedTitle,
                          style: AppTextStyles.heading2,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.submittedMessage,
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
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

class _SuccessMark extends StatelessWidget {
  const _SuccessMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: const BoxDecoration(
        color: AppColors.brandSurfaceTint,
        shape: BoxShape.circle,
      ),
      child: const ExcludeSemantics(
        child: Icon(Icons.check_rounded, size: 48, color: AppColors.brandLink),
      ),
    );
  }
}
