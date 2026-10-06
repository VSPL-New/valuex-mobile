import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/session_controller.dart';

/// Shown when the account cannot be used (suspended, banned, closed or unrecognised state).
class AccountBlockedScreen extends ConsumerWidget {
  const AccountBlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandLogo(height: 32),
              const SizedBox(height: AppSpacing.xl),
              Text(l10n.accountBlockedTitle, style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.accountBlockedMessage, style: AppTextStyles.bodySecondary),
              const Spacer(),
              BrandGradientButton(
                label: l10n.accountBlockedAction,
                onPressed: () async {
                  await ref.read(sessionControllerProvider.notifier).signOutLocally();
                  if (context.mounted) context.go(RouteNames.createAccount);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
