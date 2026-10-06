import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_assets.dart';
import '../theme/spacing.dart';

/// Rounded-square back control (Figma: Back Button Container, 35x35) inside a 44x44 tap area.
class SquareBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SquareBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).commonBack,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          width: AppSizes.minTouchTarget,
          height: AppSizes.minTouchTarget,
          // The tap area grows around the 35 px visual, which stays where the design puts it.
          child: Transform.translate(
            offset: const Offset(
              -(AppSizes.minTouchTarget - AppSizes.backButton) / 2,
              -(AppSizes.minTouchTarget - AppSizes.backButton) / 2,
            ),
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: AppSizes.backButton,
                height: AppSizes.backButton,
                child: Stack(
                  children: [
                    SvgPicture.asset(AppAssets.backButtonFrameIcon),
                    Positioned(
                      left: 12.41,
                      top: 11.66,
                      child: Transform.flip(
                        flipX: true,
                        child: SvgPicture.asset(AppAssets.backChevronIcon),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
