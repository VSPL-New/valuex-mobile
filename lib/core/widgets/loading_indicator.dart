import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../theme/colors.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.size = 32,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: size,
        width: size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          semanticsLabel: AppLocalizations.of(context).loading,
          color: color ?? AppColors.brandPrimary,
        ),
      ),
    );
  }
}
