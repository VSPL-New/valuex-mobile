import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/field_error.dart';
import '../../../../l10n/app_localizations.dart';
import '../address_messages.dart';
import '../providers/address_providers.dart';

/// Whether the address typed above is verified: checking, verified, refused (with the reason) or
/// not possible to check right now. Shown as an icon and words, announced when it changes.
class AddressVerificationStatus extends ConsumerWidget {
  const AddressVerificationStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final check = ref.watch(addressVerificationProvider);

    return switch (check.status) {
      AddressCheckStatus.idle => const SizedBox.shrink(),
      AddressCheckStatus.rejected => FieldError(text: addressCheckMessage(l10n, check.code)),
      AddressCheckStatus.checking => _Line(
          icon: Icons.hourglass_top_rounded,
          color: AppColors.brandMutedText,
          text: l10n.addressCheckChecking,
        ),
      AddressCheckStatus.verified => _Line(
          icon: Icons.check_circle_rounded,
          color: AppColors.brandLink,
          text: l10n.addressCheckVerified,
        ),
      AddressCheckStatus.unavailable => _Line(
          icon: Icons.info_outline_rounded,
          color: AppColors.brandMutedText,
          text: l10n.addressCheckUnavailable,
        ),
    };
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Line({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.sm - 2),
          Expanded(child: Text(text, style: AppTextStyles.hint)),
        ],
      ),
    );
  }
}
