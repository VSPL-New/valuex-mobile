import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/field_error.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/single_tone_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/presentation/main_nav.dart';
import '../../profile/presentation/widgets/profile_menu_section.dart';
import '../data/account_security_repository.dart';
import '../domain/account_security.dart';
import 'security_error_messages.dart';
import 'widgets/security_card.dart';

/// Profile > Account Security: sign-in details, Aadhaar status, signed-in devices and the
/// entry point for deleting the account.
class AccountSecurityScreen extends ConsumerStatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  ConsumerState<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends ConsumerState<AccountSecurityScreen> {
  bool _busy = false;
  Object? _error;

  Future<void> _refresh() async {
    ref
      ..invalidate(accountSecurityProvider)
      ..invalidate(activeSessionsProvider);
    try {
      await Future.wait([
        ref.read(accountSecurityProvider.future),
        ref.read(activeSessionsProvider.future),
      ]);
    } on Object {
      // A failed load is shown in place; the spinner just stops.
    }
  }

  Future<void> _logOutOthers(int count) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.securityLogoutOthersTitle),
        content: Text(l10n.securityLogoutOthersMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(MaterialLocalizations.of(dialog).cancelButtonLabel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.brandError),
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l10n.securityLogoutOthersConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(accountSecurityRepositoryProvider).revokeOtherSessions();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.securityLogoutOthersDone(count))));
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      ref.invalidate(activeSessionsProvider);
      if (mounted) setState(() => _busy = false);
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(accountSecurityProvider);
    final sessions = ref.watch(activeSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(l10n.securityTitle, style: AppTextStyles.heading2),
        ),
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: _back,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: summary.when(
        loading: () => Center(
          child: Semantics(
            label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
            child: const CircularProgressIndicator(),
          ),
        ),
        error: (error, _) => ErrorView(
          message: securityErrorMessage(l10n, error),
          onRetry: () => ref.invalidate(accountSecurityProvider),
        ),
        data: (security) => RefreshIndicator(
          onRefresh: _refresh,
          child: SafeArea(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _SignInDetails(security: security),
                const SizedBox(height: AppSpacing.lg),
                _Sessions(
                  sessions: sessions,
                  busy: _busy,
                  error: _error,
                  onRetry: () => ref.invalidate(activeSessionsProvider),
                  onLogOutOthers: _logOutOthers,
                ),
                const SizedBox(height: AppSpacing.lg),
                ProfileSignOutTile(
                  label: l10n.securityDeleteAccount,
                  icon: Icons.delete_outline,
                  onTap: () => showComingSoon(context),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInDetails extends StatelessWidget {
  final AccountSecurity security;

  const _SignInDetails({required this.security});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String shown(String? value) => value == null || value.isEmpty ? l10n.profileMissing : value;

    return SecuritySection(
      title: l10n.securitySectionSignIn,
      children: [
        SecurityRow(
          icon: Icons.phone_iphone,
          label: l10n.securityMobileLabel,
          value: shown(security.mobile),
          action: SecurityAction(
            label: l10n.securityChange,
            semanticLabel: l10n.securityChangeMobileA11y,
            onPressed: () => context.push(RouteNames.changeMobile),
          ),
        ),
        SecurityRow(
          icon: Icons.mail_outline,
          label: l10n.securityEmailLabel,
          value: shown(security.email),
          action: SecurityAction(
            label: l10n.securityChange,
            semanticLabel: l10n.securityChangeEmailA11y,
            onPressed: () => context.push(RouteNames.changeEmail),
          ),
        ),
        SecurityRow(
          icon: Icons.verified_user_outlined,
          label: l10n.securityAadhaarLabel,
          value:
              security.aadhaarVerified ? l10n.securityAadhaarVerified : l10n.securityAadhaarPending,
          // The status is told by an icon and words, never by colour alone.
          valueIcon: security.aadhaarVerified ? Icons.check_circle_outline : Icons.info_outline,
          hint: security.aadhaarVerified ? null : l10n.securityAadhaarHint,
          action: security.aadhaarVerified
              ? null
              : SecurityAction(
                  label: l10n.securityAadhaarVerifyNow,
                  onPressed: () => context.push(RouteNames.signupAadhaar),
                ),
        ),
      ],
    );
  }
}

class _Sessions extends StatelessWidget {
  final AsyncValue<List<ActiveSession>> sessions;
  final bool busy;
  final Object? error;
  final VoidCallback onRetry;
  final ValueChanged<int> onLogOutOthers;

  const _Sessions({
    required this.sessions,
    required this.busy,
    required this.error,
    required this.onRetry,
    required this.onLogOutOthers,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final format = DateFormat.yMMMd(locale).add_jm();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SecuritySection(
          title: l10n.securitySessionsTitle,
          children: sessions.when(
            loading: () => const [
              Padding(padding: EdgeInsets.all(AppSpacing.lg), child: LoadingIndicator()),
            ],
            error: (_, __) => [
              ErrorView(message: l10n.securitySessionsLoadFailed, onRetry: onRetry),
            ],
            data: (list) => [
              for (final session in list)
                SecurityRow(
                  icon: Icons.smartphone,
                  label: session.deviceName ?? l10n.securityUnknownDevice,
                  value: session.lastActiveAt == null
                      ? null
                      : l10n.securityLastActive(format.format(session.lastActiveAt!)),
                  hint: session.ipAddress,
                  tag: session.isCurrent ? l10n.securityThisDevice : null,
                  emphasiseLabel: true,
                ),
            ],
          ),
        ),
        ...switch (sessions.value) {
          final list? => _otherDevices(context, l10n, list),
          null => const [],
        },
      ],
    );
  }

  List<Widget> _otherDevices(
      BuildContext context, AppLocalizations l10n, List<ActiveSession> list) {
    final others = list.where((session) => !session.isCurrent).length;
    return [
      const SizedBox(height: AppSpacing.md),
      if (others == 0)
        Text(l10n.securityOnlyThisDevice, style: AppTextStyles.hint, textAlign: TextAlign.center)
      else
        SingleToneButton(
          label: l10n.securityLogoutOthers,
          onPressed: busy ? null : () => onLogOutOthers(others),
        ),
      if (error != null) ...[
        const SizedBox(height: AppSpacing.sm),
        FieldError(text: securityErrorMessage(l10n, error!)),
      ],
    ];
  }
}
