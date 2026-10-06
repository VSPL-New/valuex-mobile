import 'package:flutter/material.dart';
import 'colors.dart';

/// The single brand gradient (blue to magenta); use it for every gradient fill.
class AppGradients {
  AppGradients._();

  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brandPrimary, AppColors.brandAccent],
  );
}
