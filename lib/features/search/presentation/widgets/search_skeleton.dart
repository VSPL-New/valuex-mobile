import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../l10n/app_localizations.dart';

/// Grey card placeholders while the first page loads; static when the system asks for reduced
/// motion. Announced once as "Loading".
class SearchSkeleton extends StatelessWidget {
  static const int rows = 3;

  const SearchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final block = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brandMuted,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: const SizedBox(height: 220, width: double.infinity),
    );
    final grid = Column(
      children: [
        for (var row = 0; row < rows; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md - 4),
            child: Row(
              children: [
                Expanded(child: block),
                const SizedBox(width: AppSpacing.md - 4),
                Expanded(child: block),
              ],
            ),
          ),
      ],
    );
    return Semantics(
      label: AppLocalizations.of(context).loading,
      liveRegion: true,
      excludeSemantics: true,
      child: MediaQuery.disableAnimationsOf(context)
          ? grid
          : Shimmer.fromColors(
              baseColor: AppColors.brandMuted,
              highlightColor: AppColors.brandSurface,
              child: grid,
            ),
    );
  }
}
