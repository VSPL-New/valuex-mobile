/// Spacing, radius and control-size tokens. Use these instead of literals.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppRadius {
  AppRadius._();

  static const double sm = 6;
  static const double md = 10;
  static const double lg = 12;
  static const double xl = 16;
}

class AppSizes {
  AppSizes._();

  /// Standard buttons and text inputs.
  static const double buttonMedium = 56;

  /// Square back control (Figma).
  static const double backButton = 35.1;

  /// Smallest tap area for any control: Material's 48 dp, which also covers iOS's 44 pt.
  static const double minTouchTarget = 48;
}
