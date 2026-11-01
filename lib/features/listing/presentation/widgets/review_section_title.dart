import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/text_styles.dart';

class ReviewSectionTitle extends StatelessWidget {
  final String title;

  const ReviewSectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Text(
          title.toUpperCase(),
          style: AppTextStyles.bodySecondary.copyWith(
            color: AppColors.brandLink,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
