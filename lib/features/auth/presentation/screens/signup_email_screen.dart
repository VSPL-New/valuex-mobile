import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/motion.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../core/widgets/field_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../auth_error_messages.dart';
import '../providers/entry_controllers.dart';
import '../widgets/auth_form_scaffold.dart';

/// Registration step 3: enter the email address to verify.
class SignupEmailScreen extends ConsumerStatefulWidget {
  const SignupEmailScreen({super.key});

  @override
  ConsumerState<SignupEmailScreen> createState() => _SignupEmailScreenState();
}

class _SignupEmailScreenState extends ConsumerState<SignupEmailScreen> {
  final _fieldKey = GlobalKey();
  bool _showInvalid = false;

  void _onChanged(String value) {
    ref.read(emailInputProvider.notifier).update(value);
    ref.read(emailEntryControllerProvider.notifier).clearError();
  }

  Future<void> _submit() async {
    if (!Validators.isValidEmail(ref.read(emailInputProvider))) {
      setState(() => _showInvalid = true);
      _scrollToError();
      return;
    }
    final sent = await ref.read(emailEntryControllerProvider.notifier).sendOtp();
    if (!mounted) return;
    if (sent) {
      context.go(RouteNames.signupEmailVerify);
    } else {
      _scrollToError();
    }
  }

  /// At large text sizes the message can sit below the fold.
  void _scrollToError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _fieldKey.currentContext;
      if (context != null && context.mounted) {
        Scrollable.ensureVisible(context,
            duration: motionDuration(context, const Duration(milliseconds: 200)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Watching also keeps the typed address alive between keystrokes and the submit.
    final email = ref.watch(emailInputProvider);
    final submit = ref.watch(emailEntryControllerProvider);
    final error = submit.error;
    final errorText = error != null
        ? authErrorMessage(l10n, error)
        : _showInvalid && !Validators.isValidEmail(email)
            ? l10n.emailEntryInvalid
            : null;

    return AuthFormScaffold(
      onBack: () => context.go(RouteNames.createAccount),
      title: l10n.emailEntryTitle,
      subtitle: l10n.emailEntrySubtitle,
      content: [
        Text(l10n.emailEntryLabel, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          label: l10n.emailEntryLabel,
          child: TextField(
            key: _fieldKey,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            onChanged: _onChanged,
            onSubmitted: (_) => _submit(),
            style: AppTextStyles.input,
            cursorColor: AppColors.brandPrimary,
            decoration: InputDecoration(
              hintText: l10n.emailEntryFieldHint,
              error: errorText == null ? null : FieldError(text: errorText),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.brandMutedText),
            ),
            const SizedBox(width: 6),
            Expanded(child: Text(l10n.emailEntryHint, style: AppTextStyles.hint)),
          ],
        ),
      ],
      bottom: BrandGradientButton(
        label: l10n.emailEntrySendOtp,
        isLoading: submit.isLoading,
        onPressed: _submit,
      ),
    );
  }
}
