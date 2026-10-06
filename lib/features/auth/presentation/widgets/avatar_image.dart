import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../domain/entities/avatar_catalog.dart';

/// Placeholder avatar drawn from icons until the final artwork is supplied; the ids stay
/// the same, so swapping in images later does not touch the screens.
class AvatarImage extends StatelessWidget {
  final String avatarId;
  final double size;

  const AvatarImage({super.key, required this.avatarId, this.size = 96});

  static final _backgrounds = [
    AppColors.brandMuted,
    AppColors.brandPrimary.withValues(alpha: 0.18),
    AppColors.brandAccent.withValues(alpha: 0.18),
    AppColors.brandSurfaceTint,
  ];

  @override
  Widget build(BuildContext context) {
    final group = AvatarCatalog.groupOf(avatarId);
    final index = AvatarCatalog.groups[group]!.indexOf(avatarId).clamp(0, 3);
    final icon = switch (group) {
      AvatarGroup.male => Icons.face_6_rounded,
      AvatarGroup.female => Icons.face_3_rounded,
      AvatarGroup.neutral => Icons.person_rounded,
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: _backgrounds[index]),
      child: Icon(
        icon,
        size: size * 0.62,
        color: group == AvatarGroup.female ? AppColors.brandAccent : AppColors.brandPrimary,
      ),
    );
  }
}
