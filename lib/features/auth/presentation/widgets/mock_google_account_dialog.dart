import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

/// Development only: stands in for the Google account chooser while the backend runs the mock
/// Google verifier. Returns the account name, or null when cancelled.
Future<String?> showMockGoogleAccountDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (_) => const _MockGoogleAccountDialog(),
  );
}

class _MockGoogleAccountDialog extends StatefulWidget {
  const _MockGoogleAccountDialog();

  @override
  State<_MockGoogleAccountDialog> createState() => _MockGoogleAccountDialogState();
}

class _MockGoogleAccountDialogState extends State<_MockGoogleAccountDialog> {
  final _controller = TextEditingController(text: 'tester');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The mock verifier maps `mock-<name>` to a stable Google account, so keep the name simple.
  String? get _name {
    final cleaned = _controller.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return cleaned.isEmpty ? null : cleaned;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.googleMockTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            key: const Key('googleMockBanner'),
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.brandSurfaceTint,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.brandAccent, width: 2),
            ),
            child: Text(
              l10n.googleMockBanner,
              style: AppTextStyles.input.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.googleMockLabel),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.googleMockCancel),
        ),
        TextButton(
          onPressed: _name == null ? null : () => Navigator.of(context).pop(_name),
          child: Text(l10n.googleMockContinue),
        ),
      ],
    );
  }
}
