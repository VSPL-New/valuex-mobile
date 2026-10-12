import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/field_error.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/entities/user_profile.dart';
import '../../auth/presentation/auth_error_messages.dart';
import '../../auth/presentation/widgets/avatar_image.dart';
import '../../auth/presentation/widgets/avatar_picker_sheet.dart';
import '../data/profile_repository.dart';

/// Personal details behind the Profile page: read-only identity data plus editing of name,
/// city and avatar.
class ProfileDetailsScreen extends ConsumerStatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  ConsumerState<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends ConsumerState<ProfileDetailsScreen> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _form = GlobalKey<FormState>();
  UserProfile? _updated;
  bool _editing = false;
  bool _busy = false;
  Object? _error;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  bool _dirty(UserProfile profile) =>
      _name.text.trim() != (profile.displayName ?? '') || _city.text.trim() != (profile.city ?? '');

  Future<bool> _discard(UserProfile? profile) async {
    if (!_editing || profile == null || !_dirty(profile)) return true;
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.profileDiscard),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.profileKeepEditing),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.profileDiscardAction),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _back(UserProfile? profile) async {
    if (_busy || !await _discard(profile) || !mounted) return;
    context.pop();
  }

  void _edit(UserProfile profile) {
    _name.text = profile.displayName ?? '';
    _city.text = profile.city ?? '';
    setState(() {
      _editing = true;
      _error = null;
    });
  }

  Future<void> _save(UserProfile profile) async {
    if (_busy || !_form.currentState!.validate() || !_dirty(profile)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(profileRepositoryProvider).update(
            displayName:
                _name.text.trim() == (profile.displayName ?? '') ? null : _name.text.trim(),
            city: _city.text.trim() == (profile.city ?? '') ? null : _city.text.trim(),
          );
      if (!mounted) return;
      setState(() {
        _updated = result;
        _editing = false;
      });
      _saved();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _avatar(UserProfile profile) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final catalog = await ref.read(profileRepositoryProvider).avatars();
      if (!mounted) return;
      if (catalog.ids.isEmpty) {
        setState(() => _error = AppLocalizations.of(context).profileCatalogEmpty);
        return;
      }
      final id = await showAvatarPicker(
        context,
        selectedId: profile.avatarId ?? catalog.defaultId,
        availableIds: catalog.ids,
        confirmSelection: true,
      );
      if (id == null || id == profile.avatarId || !mounted) return;
      final result = await ref.read(profileRepositoryProvider).selectAvatar(id);
      if (!mounted) return;
      setState(() => _updated = result);
      _saved();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _saved() {
    ref.invalidate(userProfileProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).profileSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final loaded = ref.watch(userProfileProvider);
    final profile = _updated ?? loaded.value;
    return PopScope(
      canPop: !_busy && !_editing,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back(profile);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Semantics(
            header: true,
            child: Text(l10n.profileDetailsTitle, style: AppTextStyles.heading2),
          ),
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: _busy ? null : () => _back(profile),
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            if (profile != null && !_editing)
              IconButton(
                tooltip: l10n.profileEdit,
                onPressed: _busy ? null : () => _edit(profile),
                icon: const Icon(Icons.edit_outlined),
              ),
            if (_editing)
              IconButton(
                tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
                icon: const Icon(Icons.close),
                onPressed: _busy
                    ? null
                    : () async {
                        if (await _discard(profile) && mounted) {
                          setState(() {
                            _editing = false;
                            _error = null;
                          });
                        }
                      },
              ),
          ],
        ),
        body: profile == null
            ? loaded.when(
                data: (_) => const SizedBox.shrink(),
                loading: () => Center(
                  child: Semantics(
                    label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
                    child: const CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => ErrorView(
                  message: authErrorMessage(l10n, error),
                  onRetry: () => ref.invalidate(userProfileProvider),
                ),
              )
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: AvatarImage(avatarId: profile.avatarId ?? 'avatar-01')),
                      if (!_editing)
                        TextButton.icon(
                          onPressed: _busy ? null : () => _avatar(profile),
                          icon: const Icon(Icons.face_outlined),
                          label: Text(l10n.profileAvatar),
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      if (_error != null) ...[
                        FieldError(
                          text:
                              _error is String ? _error as String : authErrorMessage(l10n, _error!),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (_busy) const LinearProgressIndicator(),
                      if (_editing)
                        Form(
                          key: _form,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _name,
                                enabled: !_busy,
                                decoration: InputDecoration(
                                  labelText: l10n.profileName,
                                  errorMaxLines: 3,
                                ),
                                validator: (value) =>
                                    value?.trim() == (profile.displayName ?? '') ||
                                            Validators.isValidName(value ?? '')
                                        ? null
                                        : l10n.signupErrorName,
                                onChanged: (_) => setState(() => _error = null),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              TextFormField(
                                controller: _city,
                                enabled: !_busy,
                                decoration: InputDecoration(
                                  labelText: l10n.profileCity,
                                  errorMaxLines: 3,
                                ),
                                validator: (value) => value?.trim() == (profile.city ?? '') ||
                                        Validators.isValidCity(value ?? '')
                                    ? null
                                    : l10n.signupErrorCity,
                                onChanged: (_) => setState(() => _error = null),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AppButton(
                                label: l10n.profileSave,
                                isLoading: _busy,
                                icon: Icons.save_outlined,
                                onPressed: !_busy && _dirty(profile) ? () => _save(profile) : null,
                              ),
                            ],
                          ),
                        )
                      else ...[
                        _detail(l10n.profileName, profile.displayName),
                        _detail(l10n.profileCity, profile.city),
                      ],
                      _detail(l10n.profileMobile, profile.mobile),
                      _detail(l10n.profileEmail, profile.email),
                      if (profile.aadhaarVerified)
                        _detail(l10n.profileVerifiedName, profile.aadhaarName),
                      _detail(
                          l10n.profileGender,
                          switch (profile.gender) {
                            'MALE' => l10n.avatarGroupMale,
                            'FEMALE' => l10n.avatarGroupFemale,
                            'OTHERS' => l10n.avatarGroupNeutral,
                            _ => null,
                          }),
                      _detail(l10n.profileDob, _date(profile.dateOfBirth)),
                      _detail(l10n.profileState, profile.state),
                      _detail(l10n.profileAddress, profile.address),
                      _detail(l10n.profilePincode, profile.pincode),
                      _detail(
                        l10n.profileJoined,
                        profile.memberSince == null
                            ? null
                            : _date(profile.memberSince!.toIso8601String()),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  String? _date(String? value) {
    final date = DateTime.tryParse(value ?? '');
    return date == null
        ? null
        : DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(date);
  }

  Widget _detail(String label, String? value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.label),
            const SizedBox(height: 4),
            Text(
              value == null || value.isEmpty ? AppLocalizations.of(context).profileMissing : value,
              style: AppTextStyles.body,
            ),
          ],
        ),
      );
}
