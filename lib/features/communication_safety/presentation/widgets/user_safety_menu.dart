import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../profile/data/profile_repository.dart';
import '../../data/communication_safety_repository.dart';
import '../../domain/communication_safety.dart';
import 'block_confirmation_dialog.dart';
import 'report_sheet.dart';

enum _SafetyAction { block, report }

/// A "more options" menu with Block user and Report user for another person (US-132). It is not
/// shown for the signed-in user's own profile.
class UserSafetyMenu extends ConsumerWidget {
  final String userId;

  const UserSafetyMenu({super.key, required this.userId});

  Future<void> _block(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (!await confirmBlockUser(context)) return;
    String message;
    try {
      await ref.read(communicationSafetyRepositoryProvider).block(userId);
      message = l10n.blockUserDone;
    } on Object {
      message = l10n.blockUserFailed;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _report(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final sent = await showReportSheet(context, target: ReportTarget.user, targetId: userId);
    if (!sent) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.reportDone)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final own = ref.watch(userProfileProvider).value?.userId;
    if (own == userId) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<_SafetyAction>(
      tooltip: l10n.userSafetyMenu,
      icon: const Icon(Icons.more_vert),
      iconSize: AppSpacing.lg,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      onSelected: (action) => switch (action) {
        _SafetyAction.block => _block(context, ref),
        _SafetyAction.report => _report(context),
      },
      itemBuilder: (context) => [
        PopupMenuItem(value: _SafetyAction.block, child: Text(l10n.blockUserAction)),
        PopupMenuItem(value: _SafetyAction.report, child: Text(l10n.reportUserAction)),
      ],
    );
  }
}
