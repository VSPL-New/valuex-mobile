import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_error_messages.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/user_profile.dart';
import '../auth_error_messages.dart';
import '../providers/signup_form_controller.dart';
import '../widgets/auth_form_scaffold.dart';
import '../widgets/avatar_image.dart';
import '../widgets/avatar_picker_sheet.dart';
import '../widgets/date_of_birth_field.dart';
import '../widgets/gender_selector.dart';
import '../widgets/state_picker_field.dart';

/// Registration step 7 ("Create your profile"): the last step before the account is active.
class SignupProfileScreen extends ConsumerWidget {
  const SignupProfileScreen({super.key});

  String? _fieldError(AppLocalizations l10n, SignupFieldError? error) {
    return switch (error) {
      SignupFieldError.name => l10n.signupErrorName,
      SignupFieldError.city => l10n.signupErrorCity,
      SignupFieldError.address => l10n.signupErrorAddress,
      SignupFieldError.pincode => l10n.signupErrorPincode,
      SignupFieldError.dobFormat => l10n.signupErrorDobFormat,
      SignupFieldError.dobFuture => l10n.signupErrorDobFuture,
      null => null,
    };
  }

  Future<void> _pickDate(BuildContext context, WidgetRef ref, SignupFormState form) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: form.dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: AppLocalizations.of(context).signupDobPick,
    );
    if (picked != null) ref.read(signupFormProvider.notifier).setDateOfBirth(picked);
  }

  Future<void> _openTerms(BuildContext context, WidgetRef ref) async {
    await context.push<void>(RouteNames.terms);
    ref.read(signupFormProvider.notifier).markTermsViewed();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final form = ref.watch(signupFormProvider);
    final controller = ref.read(signupFormProvider.notifier);
    final profile = ref.watch(currentUserProfileProvider);

    ref.listen(signupFormProvider.select((state) => state.error), (previous, error) {
      if (error == null || !context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(authErrorMessage(l10n, error))));
    });

    return AuthFormScaffold(
      onBack: () => context.go(RouteNames.createAccount),
      title: l10n.signupProfileTitle,
      subtitle: l10n.signupProfileSubtitle,
      content: [
        Center(
          child: Semantics(
            button: true,
            label: l10n.signupAvatarEdit,
            excludeSemantics: true,
            onTap: () async {
              final id = await showAvatarPicker(context, selectedId: form.avatarId);
              if (id != null) controller.chooseAvatar(id);
            },
            child: GestureDetector(
              key: const Key('avatarEdit'),
              onTap: () async {
                final id = await showAvatarPicker(context, selectedId: form.avatarId);
                if (id != null) controller.chooseAvatar(id);
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AvatarImage(avatarId: form.avatarId),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.brandBackground, width: 3),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: AppColors.brandOnPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Labeled(
          label: l10n.signupNameLabel,
          child: TextField(
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            inputFormatters: [LengthLimitingTextInputFormatter(50)],
            onChanged: controller.setDisplayName,
            style: AppTextStyles.input,
            cursorColor: AppColors.brandPrimary,
            decoration: InputDecoration(
              hintText: l10n.signupNameHint,
              errorText: _fieldError(l10n, form.nameError),
            ),
          ),
        ),
        _Labeled(
          label: l10n.signupGenderLabel,
          child: GenderSelector(value: form.gender, onChanged: controller.setGender),
        ),
        _Labeled(
          label: l10n.signupDobLabel,
          child: DateOfBirthField(
            text: form.dobText,
            hint: l10n.signupDobHint,
            pickTooltip: l10n.signupDobPick,
            errorText: _fieldError(l10n, form.dobError),
            onChanged: controller.setDobText,
            onPickDate: () => _pickDate(context, ref, form),
          ),
        ),
        _Labeled(
          label: l10n.signupEmailLabel,
          child: _ReadOnlyField(
            value: profile.value?.email,
            profile: profile,
            onRetry: () => ref.invalidate(currentUserProfileProvider),
          ),
        ),
        _Labeled(
          label: l10n.signupPhoneLabel,
          child: _ReadOnlyField(
            value: profile.value?.mobile,
            profile: profile,
            onRetry: () => ref.invalidate(currentUserProfileProvider),
          ),
        ),
        _Labeled(
          label: l10n.signupStateLabel,
          child: StatePickerField(value: form.state, onChanged: controller.setState),
        ),
        _Labeled(
          label: l10n.signupCityLabel,
          child: TextField(
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            inputFormatters: [LengthLimitingTextInputFormatter(100)],
            onChanged: controller.setCity,
            style: AppTextStyles.input,
            cursorColor: AppColors.brandPrimary,
            decoration: InputDecoration(
              hintText: l10n.signupCityHint,
              errorText: _fieldError(l10n, form.cityError),
            ),
          ),
        ),
        _Labeled(
          label: l10n.signupAddressLabel,
          child: TextField(
            minLines: 3,
            maxLines: 5,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            autofillHints: const [AutofillHints.fullStreetAddress],
            inputFormatters: [LengthLimitingTextInputFormatter(255)],
            onChanged: controller.setAddress,
            style: AppTextStyles.input,
            cursorColor: AppColors.brandPrimary,
            decoration: InputDecoration(
              hintText: l10n.signupAddressHint,
              errorText: _fieldError(l10n, form.addressError),
            ),
          ),
        ),
        _Labeled(
          label: l10n.signupPincodeLabel,
          child: TextField(
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.postalCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: controller.setPincode,
            style: AppTextStyles.input,
            cursorColor: AppColors.brandPrimary,
            decoration: InputDecoration(
              hintText: l10n.signupPincodeHint,
              errorText: _fieldError(l10n, form.pincodeError),
            ),
          ),
        ),
        _TermsRow(
          viewed: form.termsViewed,
          accepted: form.termsAccepted,
          onOpenTerms: () => _openTerms(context, ref),
          onChanged: controller.setTermsAccepted,
        ),
      ],
      bottom: Column(
        children: [
          BrandGradientButton(
            label: l10n.signupSubmit,
            isLoading: form.isSubmitting,
            onPressed: form.canSubmit ? controller.submit : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(l10n.signupHaveAccount, style: AppTextStyles.bodySecondary),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(content: Text(l10n.createAccountSignInComingSoon)));
                },
                style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
                child: Text(
                  l10n.signupSignIn,
                  style: AppTextStyles.input.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  final String label;
  final Widget child;

  const _Labeled({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

/// Verified contact detail shown for reference; it cannot be edited here.
class _ReadOnlyField extends StatelessWidget {
  final String? value;
  final AsyncValue<UserProfile> profile;
  final VoidCallback onRetry;

  const _ReadOnlyField({required this.value, required this.profile, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (profile.hasError) {
      return Row(
        children: [
          Expanded(
            child: Text(
              apiErrorMessage(l10n, profile.error!),
              style: AppTextStyles.hint.copyWith(color: AppColors.brandError),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
            child: Text(l10n.commonRetry),
          ),
        ],
      );
    }

    return Semantics(
      readOnly: true,
      label: value,
      excludeSemantics: true,
      child: Container(
        height: AppSizes.buttonMedium,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.brandSurfaceTint.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.brandBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? '',
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.input.copyWith(color: AppColors.brandMutedText),
              ),
            ),
            const Icon(Icons.verified_outlined, size: 18, color: AppColors.brandMutedText),
          ],
        ),
      ),
    );
  }
}

class _TermsRow extends StatelessWidget {
  final bool viewed;
  final bool accepted;
  final VoidCallback onOpenTerms;
  final ValueChanged<bool> onChanged;

  const _TermsRow({
    required this.viewed,
    required this.accepted,
    required this.onOpenTerms,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Switch(
              value: accepted,
              onChanged: viewed ? onChanged : null,
              activeThumbColor: AppColors.brandOnPrimary,
              activeTrackColor: AppColors.brandPrimary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text.rich(
                  TextSpan(
                    style: AppTextStyles.bodySecondary,
                    children: [
                      TextSpan(text: l10n.signupTermsPrefix),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: InkWell(
                          onTap: onOpenTerms,
                          child: Text(
                            l10n.signupTermsLink,
                            style: AppTextStyles.bodySecondary.copyWith(
                              color: AppColors.brandPrimary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      TextSpan(text: l10n.signupTermsSuffix),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (!viewed)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(l10n.signupTermsHint, style: AppTextStyles.hint),
          ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
