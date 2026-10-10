import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_error_messages.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/utils/motion.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/brand_gradient_button.dart';
import '../../../../core/widgets/field_error.dart';
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
class SignupProfileScreen extends ConsumerStatefulWidget {
  const SignupProfileScreen({super.key});

  @override
  ConsumerState<SignupProfileScreen> createState() => _SignupProfileScreenState();
}

class _SignupProfileScreenState extends ConsumerState<SignupProfileScreen> {
  /// One key per field so the form can scroll to the first message.
  final _keys = {for (final field in SignupFieldError.values) field: GlobalKey()};
  final _formErrorKey = GlobalKey();

  String? _fieldError(AppLocalizations l10n, SignupFieldError? error, {bool termsViewed = true}) {
    return switch (error) {
      SignupFieldError.name => l10n.signupErrorName,
      SignupFieldError.gender => l10n.signupErrorGender,
      SignupFieldError.state => l10n.signupErrorState,
      SignupFieldError.city => l10n.signupErrorCity,
      SignupFieldError.address => l10n.signupErrorAddress,
      SignupFieldError.pincode => l10n.signupErrorPincode,
      SignupFieldError.dobFormat => l10n.signupErrorDobFormat,
      SignupFieldError.dobFuture => l10n.signupErrorDobFuture,
      SignupFieldError.terms => termsViewed ? l10n.signupErrorTerms : l10n.signupTermsHint,
      null => null,
    };
  }

  /// Brings a message into view; at large text sizes it can sit below the fold.
  void _scrollTo(GlobalKey? key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = key?.currentContext;
      if (target != null && target.mounted) {
        Scrollable.ensureVisible(target,
            duration: motionDuration(target, const Duration(milliseconds: 200)));
      }
    });
  }

  Future<void> _pickDate(SignupFormState form) async {
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

  Future<void> _openTerms() async {
    await context.push<void>(RouteNames.terms);
    ref.read(signupFormProvider.notifier).markTermsViewed();
  }

  Future<void> _chooseAvatar(SignupFormState form) async {
    final id = await showAvatarPicker(context, selectedId: form.avatarId);
    if (id != null) ref.read(signupFormProvider.notifier).chooseAvatar(id);
  }

  Future<void> _submit() async {
    final controller = ref.read(signupFormProvider.notifier);
    if (!ref.read(signupFormProvider).isValid) {
      controller.showValidation();
      final first = ref.read(signupFormProvider).firstError;
      _scrollTo(_keys[first == SignupFieldError.dobFuture ? SignupFieldError.dobFormat : first]);
      return;
    }
    final done = await controller.submit();
    if (!done) _scrollTo(_formErrorKey);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final form = ref.watch(signupFormProvider);
    final controller = ref.read(signupFormProvider.notifier);
    final profile = ref.watch(currentUserProfileProvider);
    final serverError = form.error;

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
            onTap: () => _chooseAvatar(form),
            child: GestureDetector(
              key: const Key('avatarEdit'),
              onTap: () => _chooseAvatar(form),
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
          key: _keys[SignupFieldError.name],
          label: l10n.signupNameLabel,
          labelsChild: true,
          child: TextField(
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            inputFormatters: [LengthLimitingTextInputFormatter(50)],
            onChanged: controller.setDisplayName,
            style: AppTextStyles.input,
            cursorColor: AppColors.brandPrimary,
            decoration: _decoration(l10n.signupNameHint, _fieldError(l10n, form.nameError)),
          ),
        ),
        _Labeled(
          key: _keys[SignupFieldError.gender],
          label: l10n.signupGenderLabel,
          child: GenderSelector(
            value: form.gender,
            onChanged: controller.setGender,
            errorText: _fieldError(l10n, form.genderError),
          ),
        ),
        _Labeled(
          key: _keys[SignupFieldError.dobFormat],
          label: l10n.signupDobLabel,
          child: DateOfBirthField(
            text: form.dobText,
            hint: l10n.signupDobHint,
            pickTooltip: l10n.signupDobPick,
            semanticLabel: l10n.signupDobLabel,
            errorText: _fieldError(l10n, form.dobError),
            onChanged: controller.setDobText,
            onPickDate: () => _pickDate(form),
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
          key: _keys[SignupFieldError.state],
          label: l10n.signupStateLabel,
          child: StatePickerField(
            value: form.state,
            onChanged: controller.setState,
            errorText: _fieldError(l10n, form.stateError),
          ),
        ),
        _Labeled(
          key: _keys[SignupFieldError.city],
          label: l10n.signupCityLabel,
          labelsChild: true,
          child: TextField(
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            inputFormatters: [LengthLimitingTextInputFormatter(100)],
            onChanged: controller.setCity,
            style: AppTextStyles.input,
            cursorColor: AppColors.brandPrimary,
            decoration: _decoration(l10n.signupCityHint, _fieldError(l10n, form.cityError)),
          ),
        ),
        _Labeled(
          key: _keys[SignupFieldError.address],
          label: l10n.signupAddressLabel,
          labelsChild: true,
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
            decoration: _decoration(l10n.signupAddressHint, _fieldError(l10n, form.addressError)),
          ),
        ),
        _Labeled(
          key: _keys[SignupFieldError.pincode],
          label: l10n.signupPincodeLabel,
          labelsChild: true,
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
            decoration: _decoration(l10n.signupPincodeHint, _fieldError(l10n, form.pincodeError)),
          ),
        ),
        KeyedSubtree(
          key: _keys[SignupFieldError.terms],
          child: _TermsRow(
            viewed: form.termsViewed,
            accepted: form.termsAccepted,
            errorText: _fieldError(l10n, form.termsError, termsViewed: form.termsViewed),
            onOpenTerms: _openTerms,
            onChanged: controller.setTermsAccepted,
          ),
        ),
        if (serverError != null)
          Padding(
            key: _formErrorKey,
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: FieldError(text: authErrorMessage(l10n, serverError)),
          ),
      ],
      bottom: BrandGradientButton(
        label: l10n.signupSubmit,
        isLoading: form.isSubmitting,
        onPressed: form.isSubmitting ? null : _submit,
      ),
    );
  }

  InputDecoration _decoration(String hint, String? errorText) {
    return InputDecoration(
      hintText: hint,
      error: errorText == null ? null : FieldError(text: errorText),
    );
  }
}

class _Labeled extends StatelessWidget {
  final String label;
  final Widget child;

  /// True for plain text fields, which have no label of their own for screen readers.
  final bool labelsChild;

  const _Labeled({super.key, required this.label, required this.child, this.labelsChild = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(excluding: labelsChild, child: Text(label, style: AppTextStyles.label)),
          const SizedBox(height: AppSpacing.sm),
          labelsChild ? Semantics(label: label, child: child) : child,
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
          Expanded(child: FieldError(text: apiErrorMessage(l10n, profile.error!))),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              minimumSize: const Size(AppSizes.minTouchTarget, AppSizes.minTouchTarget),
            ),
            child: Text(l10n.commonRetry, style: AppTextStyles.link),
          ),
        ],
      );
    }

    return Semantics(
      readOnly: true,
      label: value,
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.buttonMedium),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
  final String? errorText;
  final VoidCallback onOpenTerms;
  final ValueChanged<bool> onChanged;

  const _TermsRow({
    required this.viewed,
    required this.accepted,
    required this.errorText,
    required this.onOpenTerms,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final errorText = this.errorText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: '${l10n.signupTermsPrefix}${l10n.signupTermsLink}${l10n.signupTermsSuffix}',
              child: Switch(
                value: accepted,
                onChanged: viewed ? onChanged : null,
                activeThumbColor: AppColors.brandOnPrimary,
                activeTrackColor: AppColors.brandPrimary,
                inactiveThumbColor: AppColors.brandControlBorder,
                trackOutlineColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? Colors.transparent
                      : AppColors.brandControlBorder,
                ),
              ),
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
                              color: AppColors.brandLink,
                              fontWeight: FontWeight.w600,
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
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: FieldError(text: errorText),
          )
        else if (!viewed)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(l10n.signupTermsHint, style: AppTextStyles.hint),
          ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
