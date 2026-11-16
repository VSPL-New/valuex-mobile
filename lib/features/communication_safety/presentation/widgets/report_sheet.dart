import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/communication_safety_repository.dart';
import '../../domain/communication_safety.dart';

/// Opens the report sheet for [target]. Returns true when a report was sent.
Future<bool> showReportSheet(
  BuildContext context, {
  required ReportTarget target,
  required String targetId,
}) async {
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => ReportSheet(target: target, targetId: targetId),
  );
  return sent ?? false;
}

/// Picks a reason, takes optional details and sends a report (US-132). The reporter is never shown
/// anything about what happens next beyond a thank you, and the reported person is never told.
class ReportSheet extends ConsumerStatefulWidget {
  final ReportTarget target;
  final String targetId;

  const ReportSheet({super.key, required this.target, required this.targetId});

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  final TextEditingController _details = TextEditingController();
  ReportReason? _reason;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  String _label(AppLocalizations l10n, ReportReason reason) => switch (reason) {
        ReportReason.spam => l10n.reportReasonSpam,
        ReportReason.harassment => l10n.reportReasonHarassment,
        ReportReason.scamOrFraud => l10n.reportReasonScamOrFraud,
        ReportReason.inappropriateContent => l10n.reportReasonInappropriateContent,
        ReportReason.offensiveBehaviour => l10n.reportReasonOffensiveBehaviour,
        ReportReason.sharingContactDetails => l10n.reportReasonSharingContactDetails,
        ReportReason.other => l10n.reportReasonOther,
      };

  String _errorText(AppLocalizations l10n, Object error) {
    if (error is ApiError) {
      if (error.statusCode == 429) return l10n.reportRateLimited;
      if (error.statusCode == 404) return l10n.reportTargetMissing;
    }
    return l10n.reportFailed;
  }

  Future<void> _send() async {
    final reason = _reason;
    if (reason == null || _sending) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(communicationSafetyRepositoryProvider).report(
            target: widget.target,
            targetId: widget.targetId,
            reason: reason,
            details: _details.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = _errorText(l10n, error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
                header: true, child: Text(l10n.reportSheetTitle, style: AppTextStyles.heading2)),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.reportSheetSubtitle, style: AppTextStyles.bodySecondary),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final reason in ReportReason.values)
                  ChoiceChip(
                    label: Text(_label(l10n, reason)),
                    selected: _reason == reason,
                    onSelected: _sending ? null : (_) => setState(() => _reason = reason),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _details,
              enabled: !_sending,
              maxLength: reportDetailsMaxLength,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: l10n.reportDetailsLabel,
                hintText: l10n.reportDetailsHint,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                liveRegion: true,
                child:
                    Text(_error!, style: AppTextStyles.error.copyWith(color: AppColors.brandError)),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l10n.reportSubmit,
              isLoading: _sending,
              onPressed: _reason == null ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}
