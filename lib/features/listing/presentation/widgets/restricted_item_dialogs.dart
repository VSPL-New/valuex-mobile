import 'package:flutter/material.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/field_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/restricted_check.dart';
import '../listing_error_messages.dart';

const int maxAppealLength = 2000;

/// The Conditional rows the item matched, in one dialog (US-007). True when the seller chose
/// "Agree & Continue"; Cancel or a tap outside keeps them on the page.
Future<bool> showComplianceDialog(BuildContext context, RestrictedCheck check) async {
  final agreed = await showDialog<bool>(
    context: context,
    builder: (context) => _ComplianceDialog(check: check),
  );
  return agreed ?? false;
}

/// The blocked item and the rows behind it, with "Go Back" and an appeal. [onAppeal] sends the
/// reason and returns an error, or null once it was sent. True when an appeal was sent.
Future<bool> showBlockedDialog(
  BuildContext context,
  RestrictedCheck check, {
  required Future<Object?> Function(String reason) onAppeal,
}) async {
  final appealed = await showDialog<bool>(
    context: context,
    builder: (context) => _BlockedDialog(check: check, onAppeal: onAppeal),
  );
  return appealed ?? false;
}

class _PolicyList extends StatelessWidget {
  final List<RestrictionPolicy> policies;

  const _PolicyList({required this.policies});

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final policy in policies) ...[
          Semantics(
            header: true,
            child: Text(policy.titleIn(language), style: AppTextStyles.cardTitle),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(policy.messageIn(language), style: AppTextStyles.bodySecondary),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _ComplianceDialog extends StatelessWidget {
  final RestrictedCheck check;

  const _ComplianceDialog({required this.check});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Semantics(header: true, child: Text(l10n.restrictedComplianceTitle)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(child: _PolicyList(policies: check.policies)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.restrictedCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.restrictedAgreeContinue),
        ),
      ],
    );
  }
}

class _BlockedDialog extends StatefulWidget {
  final RestrictedCheck check;
  final Future<Object?> Function(String reason) onAppeal;

  const _BlockedDialog({required this.check, required this.onAppeal});

  @override
  State<_BlockedDialog> createState() => _BlockedDialogState();
}

class _BlockedDialogState extends State<_BlockedDialog> {
  final _reason = TextEditingController();
  bool _appealing = false;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final reason = _reason.text.trim();
    if (reason.isEmpty) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final error = await widget.onAppeal(reason);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _sending = false;
      _error = listingErrorMessage(AppLocalizations.of(context), error);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final suspended = widget.check.result == RestrictedResult.severeViolation;
    return AlertDialog(
      title: Semantics(
        header: true,
        child: Text(_appealing ? l10n.restrictedAppealTitle : l10n.restrictedBlockedTitle),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: _appealing
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTextField(
                      controller: _reason,
                      label: l10n.restrictedAppealHint,
                      maxLines: 4,
                      maxLength: maxAppealLength,
                      enabled: !_sending,
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_error != null) FieldError(text: _error!),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (suspended) ...[
                      Text(l10n.restrictedErrorSuspended, style: AppTextStyles.body),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _PolicyList(policies: widget.check.policies),
                  ],
                ),
        ),
      ),
      actions: _appealing
          ? [
              TextButton(
                onPressed: _sending ? null : () => setState(() => _appealing = false),
                child: Text(l10n.restrictedGoBack),
              ),
              FilledButton(
                onPressed: _sending || _reason.text.trim().isEmpty ? null : _send,
                child: Text(l10n.restrictedAppealSend),
              ),
            ]
          : [
              TextButton(
                onPressed: () => setState(() => _appealing = true),
                child: Text(l10n.restrictedAppeal),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.restrictedGoBack),
              ),
            ],
    );
  }
}
