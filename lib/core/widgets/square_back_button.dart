import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/spacing.dart';

/// Rounded-square back control (Figma: Back Button Container, 35x35).
class SquareBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SquareBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
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
    );
  }
}
