import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../auth_error_messages.dart';
import '../providers/entry_controllers.dart';
import '../widgets/auth_form_scaffold.dart';

/// Registration step 3: enter the email address to verify.
class SignupEmailScreen extends ConsumerWidget {
  const SignupEmailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final email = ref.watch(emailInputProvider);
    final submit = ref.watch(emailEntryControllerProvider);

    ref.listen(emailEntryControllerProvider, (previous, next) {
      final error = next.error;
      if (error == null || !context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(authErrorMessage(l10n, error))));
    });

    return AuthFormScaffold(
      onBack: () => context.go(RouteNames.createAccount),
      title: l10n.emailEntryTitle,
      subtitle: l10n.emailEntrySubtitle,
      content: [
        Text(l10n.emailEntryLabel, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          onChanged: ref.read(emailInputProvider.notifier).update,
          style: AppTextStyles.input,
          cursorColor: AppColors.brandPrimary,
          decoration: InputDecoration(hintText: l10n.emailEntryFieldHint),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            const Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.brandPlaceholder),
            const SizedBox(width: 6),
            Expanded(child: Text(l10n.emailEntryHint, style: AppTextStyles.hint)),
          ],
        ),
      ],
      bottom: BrandGradientButton(
        label: l10n.emailEntrySendOtp,
        isLoading: submit.isLoading,
        onPressed: Validators.isValidEmail(email)
            ? () async {
                final sent = await ref.read(emailEntryControllerProvider.notifier).sendOtp();
                if (sent && context.mounted) context.go(RouteNames.signupEmailVerify);
              }
            : null,
      ),
    );
  }
}
